# application/frontend/api/ProductClient.py
import requests
import os


class ProductClient:

    @staticmethod
    def get_products():
        url = os.environ.get('PRODUCT_SERVICE_URL', 'http://product-service:5002') + '/api/products'
        r = requests.get(url)
        products = r.json()
        return products

    @staticmethod
    def get_product(slug):
        url = os.environ.get('PRODUCT_SERVICE_URL', 'http://product-service:5002') + '/api/product/' + slug
        response = requests.request(method="GET", url=url)
        product = response.json()
        return product
