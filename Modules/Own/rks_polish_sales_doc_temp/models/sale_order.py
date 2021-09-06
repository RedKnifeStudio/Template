from odoo import api, fields, models, _

from datetime import datetime


class SaleOrder(models.Model):
    """Inherited model for adding simple bank field.

    * Payment term is without change. Inherited only for translation purposes.
    * Company bank ID is new field for choosing bank account in case of pro-forma invoice.
    """
    _inherit = 'sale.order'

    payment_term_id = fields.Many2one('account.payment.term', string='Payment Terms', check_company=True,
                                      domain="['|', ('company_id', '=', False), ('company_id', '=', company_id)]")
    company_bank_id_sale = fields.Many2one('res.partner.bank', string='Your Bank Account',
                                           domain="['|', ('partner_id', '=', False), ('partner_id', '=', 1)]",
                                           help='Your bank account number to which the pro-forma invoice will be paid.')

    @staticmethod
    def remove_hours(date, lang):
        """Method for removing time in date fields.

        :param date: Date with time.
        :param lang: Partner language.
        :return: Date without time.
        """
        if len(str(date)) > 10:
            lang_flag = False
            if lang == 'pl_PL':
                lang_flag = True

            string_date = str(date)
            converted_date = string_date[:10]

            if lang_flag is True:
                translated_date = datetime.strptime(converted_date, '%Y-%m-%d').strftime('%d.%m.%Y')
            else:
                translated_date = datetime.strptime(converted_date, '%Y-%m-%d').strftime('%m/%d/%Y')

            return translated_date
