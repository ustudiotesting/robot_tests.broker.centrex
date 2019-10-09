#!/usr/bin/python
# -*- coding: utf-8 -*-
from datetime import datetime
import pytz
import urllib
import os


tz = str(datetime.now(pytz.timezone('Europe/Kiev')))[26:]


def prepare_tender_data(role, data):
    if role == 'tender_owner':
        data['data']['procuringEntity']['name'] = u'Тестовый организатор "Банк Ликвидатор"'
    return data


def convert_date_from_item(date):
    date = datetime.strptime(date, '%d/%m/%Y %H:%M:%S').strftime('%Y-%m-%d')
    return '{}T00:00:00{}'.format(date, tz)


def adapt_paid_date(sign_date, date_paid):
    time = sign_date[-8:]
    date = datetime.strptime(date_paid, '%Y-%m-%d')
    return '{} {}'.format(datetime.strftime(date, '%d/%m/%Y'), time)


def convert_date(date):
    date = datetime.strptime(date, '%d/%m/%Y %H:%M:%S').strftime('%Y-%m-%dT%H:%M:%S.%f')
    return '{}{}'.format(date, tz)


def convert_date_for_item(date):
    date = datetime.strptime(date, '%Y-%m-%dT%H:%M:%S{}'.format(tz)).strftime('%d/%m/%Y %H:%M')
    return '{}'.format(date)


def convert_date_for_auction(date):
    date = datetime.strptime(date, '%Y-%m-%dT%H:%M:%S.%f{}'.format(tz)).strftime('%d/%m/%Y %H:%M')
    return '{}'.format(date)

def convert_date_for_datePaid(date):
    date = datetime.strptime(date, '%Y-%m-%dT%H:%M:%S.%f{}'.format(tz)).strftime('%d/%m/%Y %H:%M:%S')
    return date


def dgf_decision_date_from_site(date):
    return u'{}-{}-{}'.format(date[-4:], date[-7:-5], date[-10:-8])


def dgf_decision_date_for_site(date):
    return u'{}/{}/{}'.format(date[-2:], date[-5:-3], date[-10:-6])


def adapted_dictionary(value):
    return{
        u"з урахуванням ПДВ": True,
        u"без урахуванням ПДВ": False,
        u"True": "1",
        u"False": "0",
        u"Оголошення аукціону з продажу майна банків": "dgfOtherAssets",
        u'Класифікація згідно CAV': 'CAV',
        u'Класифікація згідно CAV-PS': 'CAV-PS',
        u'Класифікація згідно CPV': 'CPV',
        u'Очiкування пропозицiй': 'active.tendering',
        u'Перiод уточнень': 'active.enquires',
        u'Аукцiон': 'active.auction',
        u'Квалiфiкацiя переможця': 'active.qualification',
        u'Торги не відбулися': 'unsuccessful',
        u'Аукціон завершено. Договір підписано.': 'complete',
        u'Торги скасовано': 'cancelled',
        u'Торги були відмінені.': 'active',
        u'Очікується підписання договору': 'active',
        u'Очікується протокол': 'pending.verification',
        u'На черзі': 'pending.waiting',
        u'На розглядi': 'pending',
        u'Рiшення скасовано': 'cancelled',
        u'Оплачено, очікується підписання договору': 'active',
        u'Дискваліфіковано': 'unsuccessful',
        u'майна банків': 'dgfOtherAssets',
        u'прав вимоги за кредитами': 'dgfFinancialAssets',
        u'Голландський аукціон': 'dgfInsider',
        u'Юридична Інформація про Майданчики': 'x_dgfPlatformLegalDetails',
        u'Презентація': 'x_presentation',
        u'Договір NDA': 'x_nda',
        u'Паспорт торгів': 'tenderNotice',
        u'Публічний Паспорт Активу': 'technicalSpecifications',
        u'Ілюстрації': 'illustration',
        u'Кваліфікаційні вимоги': 'evaluationCriteria',
        u'Типовий договір': 'contractProforma',
        u'Погодження змін до опису лоту': 'clarifications',
        u'Посилання на Публічний Паспорт Активу': 'x_dgfPublicAssetCertificate',
        u'Інформація про деталі ознайомлення з майном у кімнаті даних': 'x_dgfAssetFamiliarization',
        u'Договір підписано та активовано': 'active',
        u'Оголошення аукціону з продажу прав вимоги за кредитами': 'dgfFinancialAssets',
        u'Оголошення з продажу на «голландському» аукціоні': 'dgfInsider',
        u'Торги відмінено': 'cancelled',
        u'Очікується опублікування протоколу': 'active.qualification',
        u'Відмова від очікування': 'cancelled'
    }.get(value, value)


def adapt_data(field, value):
    if field == 'tenderAttempts':
        value = int(value)
    elif 'dutchSteps' in field:
        value = int(value)
    elif field == 'value.amount':
        value = float(value)
    elif field == 'minimalStep.amount':
        value = float(value.split(' ')[0])
    elif field == 'guarantee.amount':
        value = float(value.split(' ')[0])
    elif field == 'quantity':
        value = float(value.replace(',', '.'))
    elif field == 'minNumberOfQualifiedBids':
        value = int(value)
    elif 'contractPeriod' in field:
        value = convert_date_from_item(value)
    elif 'tenderPeriod' in field or 'auctionPeriod' in field or 'datePaid' in field:
        value = convert_date(value)
    elif 'dgfDecisionDate' in field:
        value = dgf_decision_date_from_site(value)
    elif 'dgfDecisionID' in field:
        value = value[-6:]
    else:
        value = adapted_dictionary(value)
    return value


def download_file(url, filename, folder):
    urllib.urlretrieve(url, ('{}/{}'.format(folder, filename)))


def my_file_path():
    return os.path.join(os.getcwd(), 'src', 'robot_tests.broker.centrex', 'Doc.pdf')