# config.py
import os
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(__file__), '.env')

if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path)


class Config:
    SECRET_KEY = 'y2BH8xD9pyZhDT5qkyZZRgjcJCMHdQ'
    WTF_CSRF_SECRET_KEY = 'VyOyqv5Fm3Hs3qB1AmNeeuvPpdRqTJbTs5wKvWCS'


class DevelopmentConfig(Config):
    ENV = "development"
    DEBUG = True


class ProductionConfig(Config):
    ENV = "production"
    DEBUG = False
    WTF_CSRF_ENABLED = False  # Temporarily disable CSRF for testing
    # Use environment variables for Kubernetes deployment
    USER_SERVICE_URL = os.environ.get('USER_SERVICE_URL', 'http://user-service:5001')
    PRODUCT_SERVICE_URL = os.environ.get('PRODUCT_SERVICE_URL', 'http://product-service:5002')
    ORDER_SERVICE_URL = os.environ.get('ORDER_SERVICE_URL', 'http://order-service:5003')


config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}

