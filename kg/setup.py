from setuptools import setup, find_packages

setup(
    name='kg_plugin',
    version='1.0.0',
    author='Layanne El Assaad',
    description='Knowledge graph plugin with semantic search and YAML query DSL',
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    packages=find_packages(where='src'),
    package_dir={'': 'src'},
    package_data={
        'kg_plugin': [
            'static/js/*.js',
            'inject/*.jinja2',
            'override/*.jinja2',
            'templates/*.jinja2'
        ]
    },
    include_package_data=True,
    install_requires=[
        'networkx>=3.0',
        'sentence-transformers>=2.2.0',
        'faiss-cpu>=1.7.0',
        'numpy>=1.21.0',
        'pandas>=1.3.0',
        'unstructured>=0.10.0',
        'pyyaml>=6.0',
        'scikit-learn>=1.0.0',
        'fastapi>=0.68.0',
        'pydantic>=1.8.0',
        'langchain>=0.0.300'
    ],
    entry_points={
        'console_scripts': [
            'kg_plugin_scheduler=kg_plugin.scheduler:main',
        ],
    },
    classifiers=[
        'Programming Language :: Python :: 3',
        'Operating System :: OS Independent',
    ],
    python_requires='>=3.8',
)
