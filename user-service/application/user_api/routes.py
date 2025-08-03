# application/user_api/routes.py
from . import user_api_blueprint
from .. import db, login_manager
from ..models import User
from flask import make_response, request, jsonify
from flask_login import current_user, login_user, logout_user, login_required

from passlib.hash import sha256_crypt


@login_manager.user_loader
def load_user(user_id):
    return User.query.filter_by(id=user_id).first()


@login_manager.request_loader
def load_user_from_request(request):
    api_key = request.headers.get('Authorization')
    if api_key:
        api_key = api_key.replace('Basic ', '', 1)
        user = User.query.filter_by(api_key=api_key).first()
        if user:
            return user
    return None


@user_api_blueprint.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for Kubernetes"""
    try:
        # Test database connection
        db.session.execute('SELECT 1')
        return jsonify({
            'status': 'healthy',
            'service': 'user-service',
            'database': 'connected'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'service': 'user-service',
            'database': 'disconnected',
            'error': str(e)
        }), 503


@user_api_blueprint.route('/api/users', methods=['GET'])
def get_users():
    data = []
    for row in User.query.all():
        data.append(row.to_json())

    response = jsonify(data)
    return response


@user_api_blueprint.route('/api/user/create', methods=['POST'])
def post_register():
    try:
        # Handle both form data and JSON
        if request.is_json:
            data = request.get_json()
            first_name = data.get('first_name')
            last_name = data.get('last_name')
            email = data.get('email')
            username = data.get('username')
            password = data.get('password')
        else:
            first_name = request.form.get('first_name')
            last_name = request.form.get('last_name')
            email = request.form.get('email')
            username = request.form.get('username')
            password = request.form.get('password')

        # Validation
        if not all([first_name, last_name, email, username, password]):
            return jsonify({'message': 'All fields are required'}), 400

        # Check if user already exists
        if User.query.filter_by(username=username).first():
            return jsonify({'message': 'Username already exists'}), 409
        
        if User.query.filter_by(email=email).first():
            return jsonify({'message': 'Email already exists'}), 409

        # Create user
        user = User()
        user.email = email
        user.first_name = first_name
        user.last_name = last_name
        user.password = sha256_crypt.hash(str(password))
        user.username = username
        user.authenticated = True

        db.session.add(user)
        db.session.commit()

        response = jsonify({'message': 'User created successfully', 'result': user.to_json()})
        return response

    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Registration failed', 'error': str(e)}), 500


@user_api_blueprint.route('/api/user/login', methods=['POST'])
def post_login():
    username = request.form['username']
    user = User.query.filter_by(username=username).first()
    if user:
        if sha256_crypt.verify(str(request.form['password']), user.password):
            user.encode_api_key()
            db.session.commit()
            login_user(user)

            return make_response(jsonify({'message': 'Logged in', 'api_key': user.api_key}))

    return make_response(jsonify({'message': 'Not logged in'}), 401)


@user_api_blueprint.route('/api/user/logout', methods=['POST'])
def post_logout():
    if current_user.is_authenticated:
        logout_user()
        return make_response(jsonify({'message': 'You are logged out'}))
    return make_response(jsonify({'message': 'You are not logged in'}))


@user_api_blueprint.route('/api/user/<username>/exists', methods=['GET'])
def get_username(username):
    item = User.query.filter_by(username=username).first()
    if item is not None:
        response = jsonify({'result': True})
    else:
        response = jsonify({'message': 'Cannot find username'}), 404
    return response


@login_required
@user_api_blueprint.route('/api/user', methods=['GET'])
def get_user():
    if current_user.is_authenticated:
        return make_response(jsonify({'result': current_user.to_json()}))
    return make_response(jsonify({'message': 'Not logged in'})), 401