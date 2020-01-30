from setuptools import setup

setup (
    name='datatrace-web',
    version='1.0.1',
    maintainer="Andrey Zhidenkov",
    maintainer_email="pensnarik@gmail.com",
    packages=['datatrace_web'],
    scripts=['datatrace_web.py'],
    include_package_data=True,
    zip_safe=False,
    data_files=[('etc/uwsgi/apps-available', ['datatrace-uwsgi.ini']), ('lib/systemd/system', ['datatrace-web.service']),
                ('etc', ['datatrace_web.config'])],
    install_requires=['Flask', 'psycopg2', 'uWSGI']
)
