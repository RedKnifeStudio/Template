from odoo import api, fields, models, _


class Company(models.Model):
    _inherit = 'res.company'

    regon = fields.Char(string='REGON Number', help='Nine-digit REGON number.')
