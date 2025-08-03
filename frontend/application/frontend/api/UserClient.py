# application/frontend/api/UserClient.py
import requests
import os
from flask import session

class UserClient:
    @staticmethod
    def get_user_service_url():
        return os.environ.get('USER_SERVICE_URL', 'http://user-service.user-service.svc.cluster.local:5001')

    @staticmethod
    def post_user_create_direct(username, first_name, last_name, email, password):
        try:
            url = f"{UserClient.get_user_service_url()}/api/user/create"
            data = {
                'username': username,
                'first_name': first_name,
                'last_name': first_name,
                'email': email,
                'password': password
            }
            response = requests.post(url, data=data, timeout=10)
            if response.status_code == 200:
                return response.json()
            return None
        except Exception as e:
            print(f"Error creating user: {e}")
            return None

    @staticmethod
    def does_exist(username):
        try:
            url = f"{UserClient.get_user_service_url()}/api/user/{username}/exists"
            response = requests.get(url, timeout=10)
            return response.status_code == 200
        except Exception:
            return False

    @staticmethod
    def post_login(form):
        try:
            url = f"{UserClient.get_user_service_url()}/api/user/login"
            data = {
                'username': form.username.data,
                'password': form.password.data
            }
            response = requests.post(url, data=data, timeout=10)
            if response.status_code == 200:
                result = response.json()
                return result.get('api_key')
            return None
        except Exception as e:
            print(f"Error logging in: {e}")
            return None

    @staticmethod
    def get_user():
        try:
            api_key = session.get('user_api_key')
            if not api_key:
                return None
                
            url = f"{UserClient.get_user_service_url()}/api/user"
            headers = {'Authorization': f'Basic {api_key}'}
            response = requests.get(url, headers=headers, timeout=10)
            if response.status_code == 200:
                return response.json()
            return None
        except Exception as e:
            print(f"Error getting user: {e}")
            return None

