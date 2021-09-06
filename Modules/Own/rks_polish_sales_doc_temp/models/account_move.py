from odoo import api, fields, models, _

import requests
from datetime import date, timedelta


class AccountMove(models.Model):
    """Overwritten model for adding new fields required by polish accounting.

    * Invoice date due is without change. Inherited only for translation purposes.
    * Invoice payment term is without change. Inherited only for translation purposes.
    * Invoice date is without change. Inherited only for translation purposes.
    * Sale date is date of transaction for the invoice.
    * Currency code field for helping set a domain.
    * Current currency rate is float field for storing currency rate used in invoice date.
    * Invoice partner bank field is without change. Inherited only for translation purposes.
    * Currency Table Number field stores NBP table number get from API.
    * NBP Currency Rate is a currency rate from NBP.
    * NBP table date is date of requested NBP table.
    * Issuer field for check if issuer sign is needed.
    * Receiver field for check if receiver sign is needed.
    """
    _inherit = 'account.move'

    @api.model
    def _get_default_invoice_date(self):
        """Set today's date as default.

        :return: Date
        """
        return fields.Date.today() if self._context.get('default_type', 'entry') in (
            'in_invoice', 'in_refund', 'in_receipt'
        ) else False

    @api.depends('invoice_date')
    def _set_invoice_dates(self):
        """Set sale date the same as invoice date.

        :return: Sale Date
        """
        for invoice in self:
            invoice.sale_date = invoice.invoice_date

    @api.depends('currency_id')
    def _set_bank_on_curr(self):
        """Set bank account based on currency used in the invoice, and get currency code.

        :return: Bank Account / Currency code
        """
        for invoice in self:
            currency_bank = self.env['res.partner.bank'].search([
                ('partner_id', '=', invoice.company_id.id),
                ('currency_id', '=', invoice.currency_id.id)
            ])
            invoice.invoice_partner_bank_id = currency_bank.id
            invoice.currency_name = invoice.currency_id.name

    invoice_date_due = fields.Date(string='Due Date', readonly=True, index=True, copy=False,
                                   states={'draft': [('readonly', False)]})
    invoice_payment_term_id = fields.Many2one(
        'account.payment.term', string='Payment Terms', readonly=True, states={'draft': [('readonly', False)]},
        domain="['|', ('company_id', '=', False), ('company_id', '=', company_id)]"
    )
    invoice_date = fields.Date(string='Invoice/Bill Date', readonly=True, index=True, copy=False,
                               states={'draft': [('readonly', False)]}, default=_get_default_invoice_date)
    sale_date = fields.Date(string='Sale Date', help='Invoice sale date.', compute='_set_invoice_dates', readonly=False,
                            store=True)
    currency_name = fields.Char(string='Currency Code', compute='_set_bank_on_curr',
                                help='Help field for storing currency code.')
    invoice_partner_bank_id = fields.Many2one('res.partner.bank', string='Bank Account',
                                              help='Bank Account Number to which the invoice will be paid. '
                                                   'A Company bank account if this is a Customer Invoice or '
                                                   'Vendor Credit Note, otherwise a Partner bank account number.',
                                              domain="['|', ('company_id', '=', False), "
                                                     "('company_id', '=', company_id)]", compute='_set_bank_on_curr')
    currency_table_number = fields.Char(string='Currency Rate Table No', readonly=True,
                                        help='Currency rate table downloaded from NBP API.')
    currency_rate_nbp = fields.Float(string='NBP Currency Rate', readonly=True, digits='NBP Currency Rate',
                                     help='Currency rate from NBP API.')
    nbp_currency_date = fields.Date(string='NBP table date', readonly=True,
                                    help='Date from which this table was requested.')
    issuer = fields.Boolean(string='Issuer signature', default=True,
                            help="Enable this option if you want to display a space for the salesperson's signature.")
    receiver = fields.Boolean(string='Recipients signature', default=False,
                              help="Enable this option if you want to display a space for the Recipient's signature.")
    print_product_label = fields.Boolean(string='Print Product Label', default=False,
                                         help='Check this, if you want to print product labels on invoice.')

    def get_nbp_table(self):
        """API method for connecting to NBP for requesting table number, currency, and date.

        :return: Table number / Currency rate / Table date.
        """
        # First try to connect.
        if self.invoice_date:
            api_date = self.invoice_date
        else:
            api_date = date.today()

        api_date = api_date - timedelta(days=1)
        url = f'http://api.nbp.pl/api/exchangerates/rates/A/{self.currency_id.name}/{api_date}/'
        response = requests.get(url)
        status_code = response.status_code

        # If there is no table for invoice date, then try for every day backwards.
        if status_code == 404:
            while status_code != 200:
                api_date = api_date - timedelta(days=1)
                url = f'http://api.nbp.pl/api/exchangerates/rates/A/{self.currency_id.name}/{api_date}/'
                response = requests.get(url)
                status_code = response.status_code

        # After successful connection, assign table information to record fields.
        if status_code == 200:
            self.currency_table_number = response.json()['rates'][0]['no']
            self.currency_rate_nbp = response.json()['rates'][0]['mid']
            self.nbp_currency_date = response.json()['rates'][0]['effectiveDate']

    def write(self, values):
        """Overwritten write method for running an API request.

        :return: API currency table response | Invoice post.
        """
        res = super(AccountMove, self).write(values)
        if ('invoice_date' in values and self.currency_id.name != 'PLN') \
                or ('currency_id' in values and values['currency_id'] != 17):
            self.get_nbp_table()

        return res
