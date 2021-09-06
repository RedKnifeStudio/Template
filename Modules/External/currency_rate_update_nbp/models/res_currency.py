# -*- coding: utf-8 -*-

from odoo import models
from datetime import date, datetime, timedelta
import requests
import logging
logger = logging.getLogger(__name__)


class ResCurrency(models.Model):

    _inherit = 'res.currency'

    def nbp_currency_rate_update(self):
        ctx = dict(self.env.context)
        ctx['active_test'] = False
        self = self.with_context(ctx)
        for table in 'AB':
            response = requests.get('http://api.nbp.pl/api/exchangerates/tables/{}/{}/{}'.
                                    format(table, str(date.today() - timedelta(days=30)), str(date.today()))).json()
            for company in self.env['res.company'].search([('currency_id', '=', self.env.ref('base.PLN').id)]):
                for day_response in response:
                    odoo_date = (datetime.strptime(day_response['effectiveDate'], '%Y-%m-%d')+timedelta(days=1)).date()
                    for rate in day_response['rates']:
                        currency = self.env['res.currency'].search([('name', '=', rate['code'])])
                        if not currency:
                            continue
                        rate_obj = self.env['res.currency.rate'].search([
                            ('name', '=', odoo_date),
                            ('currency_id', '=', currency.id),
                            ('company_id', '=', company.id)])
                        if not rate_obj:
                            logger.info('Added currency rate. Currency: {}; Date: {}; Value: {};'.format(
                                currency.name, odoo_date, 1.0/rate['mid']))
                            self.env['res.currency.rate'].create(dict(
                                name=str(odoo_date),
                                currency_id=currency.id,
                                company_id=company.id,
                                rate=1.0/rate['mid']))
