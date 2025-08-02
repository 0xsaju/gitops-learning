# config.py
import os
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path)


class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key'
    SQLALCHEMY_TRACK_MODIFICATIONS = False


class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://dbuser:testpass123@host.docker.internal:3306/order_management_dev'
    SQLALCHEMY_ECHO = True


class ProductionConfig(Config):
    DEBUG = False
    # Use environment variables for Kubernetes deployment
    MYSQL_HOST = os.environ.get('MYSQL_HOST', 'mysql')
    MYSQL_PORT = os.environ.get('MYSQL_PORT', '3306')
    MYSQL_USER = os.environ.get('MYSQL_USER', 'flask_user')
    MYSQL_PASSWORD = os.environ.get('MYSQL_PASSWORD', 'FlaskPassWord123')
    MYSQL_DATABASE = os.environ.get('MYSQL_DATABASE', 'flask_microservices')
    
    SQLALCHEMY_DATABASE_URI = f'mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DATABASE}'
    SQLALCHEMY_ECHO = False

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}


