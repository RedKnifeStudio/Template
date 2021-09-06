{
    'name': 'RedKnife Sales Document Templates (14)',
    'summary': 'Set of modified documents views in Odoo 14 for RedKnife.',
    'description': '''
    Module for changing the base documents views in Odoo 14 based on standard style.
    ''',
    'author': 'RedKnife Studio Sp. z o.o.',
    'website': 'https://redknife-studio.pl',
    'category': 'Invoicing Payments',
    'version': '[V14] 2.6.8',
    'depends': [
        'base',
        'account',
        'sale',
        'sale_management',
        'currency_rate_update_nbp'
    ],
    'data': [
        'data/currency_rate_data.xml',
        'report/account_document_template.xml',
        'report/external_layout_background_template.xml',
        'report/header_footer_document_template.xml',
        'report/sale_document_template.xml',
        'views/account_model_view.xml',
        'views/res_company_model_view.xml',
        'views/sale_model_view.xml'
    ],
    'installable': True,
    'auto_install': False
}
