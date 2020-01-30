import os
import pwd
import grp

from setuptools import setup, Command
from setuptools.command.install import install
from distutils.util import convert_path

def prepare():
    if os.getuid() != 0:
        raise Exception('This command must be run under root')

    try:
        grp.getgrnam('datatrace')
    except KeyError:
        os.system('groupadd datatrace')

    try:
        pwd.getpwnam('datatrace')
    except KeyError:
        os.system('useradd datatrace -g datatrace --shell /usr/sbin/nologin')

    if not os.path.exists('/var/log/datatrace'):
        os.mkdir('/var/log/datatrace')

    os.system('chown datatrace:datatrace /var/log/datatrace')
    os.system('chmod g+w /var/log/datatrace')

    print('User datatrace and directory /var/log/datatrace have been created successfully')

def get_version():
    d = {}
    with open('datatrace/__init__.py') as fp:
        exec(fp.read(), d)

    return d["__version__"]

class PrepareUser(Command):

    description = 'Creates the user and /var/log/datatrace directory'
    user_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        prepare()

class PrepareInstall(install):

    def run(self):
        prepare()
        install.run(self)
        print('Please, specify the value for environment variable $DATATRACE_DB in')
        print('datatrace user .bash_profile file')

setup(name="datatrace",
      description="Crawler",
      license="Commercial",
      version=get_version(),
      maintainer="Andrey Zhidenkov",
      maintainer_email="pensnarik@gmail.com",
      url="http://parselab.ru",
      scripts=['bin/datatrace', 'bin/datatrace-dispatcher'],
      packages=['datatrace', 'datatrace.spyder'],
      install_requires=["psycopg2", "requests", "timeout-decorator", "lxml"],
      data_files=[('lib/systemd/system', ['datatrace@.service', 'datatrace-dispatcher.service'])],
      cmdclass={'prepare': PrepareUser, 'install': PrepareInstall}
)
