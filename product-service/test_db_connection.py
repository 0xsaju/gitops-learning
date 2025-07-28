import pymysql

try:
    conn = pymysql.connect(
        host='product-db',
        user='dbuser',
        password='testpass123',
        database='product_catalog',
        port=3306
    )
    with conn.cursor() as cursor:
        cursor.execute('SHOW DATABASES;')
        print('Connection successful! Databases:')
        for row in cursor.fetchall():
            print(row[0])
    conn.close()
except Exception as e:
    print('Connection failed:', e) 