#!/usr/bin/python
# -*- coding: utf-8 -*-

from datetime import datetime
from iso8601 import parse_date
from pytz import timezone
import os
import urllib


def convert_time(date):
    date = datetime.strptime(date, "%d/%m/%Y %H:%M:%S")
    return timezone('Europe/Kiev').localize(date).strftime('%Y-%m-%dT%H:%M:%S.%f%z')


def convert_decision_date(date):
    date_obj = datetime.strptime(date, "%d/%m/%Y")
    return date_obj.strftime("%Y-%m-%d")

def convert_datetime_to_centrex_format(isodate):
    iso_dt = parse_date(isodate)
    day_string = iso_dt.strftime("%d/%m/%Y %H:%M")
    return day_string


def convert_date_to_template_format(date, template_in, template_out):
    return datetime.strptime(date, template_in).strftime(template_out)


def convert_string_from_dict_centrex(string):
    return {
        u"грн": u"UAH",
        u"True": u"1",
        u"False": u"0",
        u'Класифікація згідно CAV': u'CAV',
        u'Класифікація згідно CAV-PS': u'CAV-PS',
        u'Класифікація згідно CPV': u'CPV',
        u'з урахуванням ПДВ': True,
        u'без урахуванням ПДВ': False,
        u'очiкування пропозицiй': u'active.tendering',
        u'перiод уточнень': u'active.enquires',
        u'аукцiон': u'active.auction',
        u'квалiфiкацiя переможця': u'active.qualification',
        u'торги не відбулися': u'unsuccessful',
        u'продаж завершений': u'complete',
        u'торги скасовано': u'cancelled',
        u'торги були відмінені.': u'active',
        u'Юридична Інформація про Майданчики': u'x_dgfPlatformLegalDetails',
        u'Презентація': u'x_presentation',
        u'Договір про нерозголошення (NDA)': u'x_nda',
        u'Публічний Паспорт Активу': u'x_dgfPublicAssetCertificate',
        u'Технічні специфікації': u'x_technicalSpecifications',
        u'Паспорт торгів': u'x_tenderNotice',
        u'Повідомлення про аукціон': u'notice',
        u'Ілюстрації': u'illustration',
        u'Критерії оцінки': u'evaluationCriteria',
        u'Пояснення до питань заданих учасниками': u'clarifications',
        u'Інформація про учасників': u'bidders',
        u'майна замовника': u'dgfOtherAssets',
        u'очікується протокол': u'pending.verification',
        u'на черзі': u'pending.waiting',
        u'очікується підписання договору': u'pending.payment',
        u'оплачено, очікується підписання договору': u'active',
        u'рiшення скасовано': u'cancelled',
        u'дискваліфіковано': u'unsuccessful',
    }.get(string, string)


def adapt_procuringEntity(role_name, tender_data):
    if role_name == 'tender_owner':
        tender_data['data']['procuringEntity']['name'] = u"ТЕСТОВА КОМПАНІЯ"
    return tender_data


def adapt_view_data(value, field_name):
    if field_name == 'value.amount':
        value = float(value)
    elif field_name in ('minimalStep.amount', 'guarantee.amount'):
        value = float(value.split(' ')[0])
    elif field_name == 'tenderAttempts':
        value = int(value)
    elif 'quantity' in field_name:
        value = float(value.split(' ')[0])
    elif 'questions' in field_name and '.date' in field_name:
        value = convert_time(value.split(' - ')[0])
    elif field_name == 'dgfDecisionDate':
        return convert_decision_date(value.split(" ")[-1])
    elif field_name == 'dgfDecisionID':
        value = value.split(" ")[1]
    elif 'Date' in field_name:
        value = convert_time(value)
    elif field_name == 'minNumberOfQualifiedBids':
        value = int(value)
    return convert_string_from_dict_centrex(value)


def adapt_view_item_data(value, field_name):
    if 'quantity' in field_name:
        value = float(value.replace(",", "."))
    elif 'contractPeriod' in field_name:
        value = "{}T00:00:00+02:00".format(convert_date_to_template_format(value, "%d/%m/%Y %H:%M:%S", "%Y-%m-%d"))
    return convert_string_from_dict_centrex(value)


def get_upload_file_path():
    return os.path.join(os.getcwd(), 'src', 'robot_tests.broker.centrex', 'testFileForUpload.txt')


def centrex_download_file(url, file_name, output_dir):
    urllib.urlretrieve(url, ('{}/{}'.format(output_dir, file_name)))
