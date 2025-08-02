# application/frontend/api/OrderClient.py
from flask import session
import requests
import os


class OrderClient:
    @staticmethod
    def get_order():
        headers = {
            'Authorization': 'Basic ' + session['user_api_key']
        }
        url = os.environ.get('ORDER_SERVICE_URL', 'http://order-service:5003') + '/api/order'
        response = requests.request(method="GET", url=url, headers=headers)
        order = response.json()
        return order

    @staticmethod
    def post_add_to_cart(product_id, qty=1):
        payload = {
            'product_id': product_id,
            'qty': qty
        }
        url = os.environ.get('ORDER_SERVICE_URL', 'http://order-service:5003') + '/api/order/add-item'

        headers = {
            'Authorization': 'Basic ' + session['user_api_key']
        }
        response = requests.request("POST", url=url, data=payload, headers=headers)
        if response:
            order = response.json()
            return order

    @staticmethod
    def post_checkout():
        url = os.environ.get('ORDER_SERVICE_URL', 'http://order-service:5003') + '/api/order/checkout'

        headers = {
            'Authorization': 'Basic ' + session['user_api_key']
        }
        response = requests.request("POST", url=url, headers=headers)
        order = response.json()
        return order

    @staticmethod
    def get_order_from_session():
        default_order = {
            'items': {},
            'total': 0,
        }
        return session.get('order', default_order)
