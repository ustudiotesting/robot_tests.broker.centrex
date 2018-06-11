*** Settings ***
Library  Selenium2Library
Library  BuiltIn
Library  Collections
Library  String
Library  DateTime
Library  centrex_service.py

*** Variables ***


*** Keywords ***

Підготувати клієнт для користувача
    [Arguments]  ${username}
    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys
    Run Keyword If  '${USERS.users['${username}'].browser}' in 'Chrome chrome'  Run Keywords
    ...  Call Method  ${chrome_options}  add_argument  --headless
    ...  AND  Create Webdriver  Chrome  alias=my_alias  chrome_options=${chrome_options}
    ...  AND  Go To  ${USERS.users['${username}'].homepage}
    ...  ELSE  Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=my_alias
    Set Window Size  ${USERS.users['${username}'].size[0]}  ${USERS.users['${username}'].size[1]}
    Run Keyword If  'Viewer' not in '${username}'  Run Keywords
    ...  Авторизація  ${username}
    ...  AND  Run Keyword And Ignore Error  Закрити Модалку
    Run Keyword And Ignore Error  Закрити Модалку


Підготувати дані для оголошення тендера
    [Arguments]  ${username}  ${initial_tender_data}  ${role}
    ${tender_data}=  prepare_tender_data  ${role}  ${initial_tender_data}
    [Return]  ${tender_data}


Оновити сторінку з тендером
    [Arguments]  ${tender_uaid}  ${username}
    Switch Browser  my_alias
    Reload Page


Авторизація
    [Arguments]  ${username}
    Click Element  xpath=//*[contains(@href, "/login")]
    Wait Until Element Is Visible  xpath=//button[@name="login-button"]
    Input Text  xpath=//input[@id="loginform-username"]  ${USERS.users['${username}'].login}
    Input Text  xpath=//input[@id="loginform-password"]  ${USERS.users['${username}'].password}
    Click Element  xpath=//button[@name="login-button"]


###############################################################################################################
########################################### ASSETS ############################################################
###############################################################################################################

Створити об'єкт МП
    [Arguments]  ${username}  ${tender_data}
    ${data}=  Get Data  ${tender_data}
    ${decisions}=   Get From Dictionary   ${tender_data.data}   decisions
    ${items}=  Get From Dictionary  ${tender_data.data}  items
    Click Element  xpath=//button[@data-target="#toggleRight"]
    Wait Until Element Is Visible  xpath=//nav[@id="toggleRight"]/descendant::a[contains(@href, "/assets/index")]
    Click Element  xpath=//nav[@id="toggleRight"]/descendant::a[contains(@href, "/assets/index")]
    centrex.Закрити Модалку
    Click Element  xpath=//a[contains(@href, "/buyer/asset/create")]
    Input Text  id=asset-title  ${data.title}
    Input Text  id=asset-description  ${data.description}
    Input Text  id=decision-0-title  ${decisions[0].title}
    Input Text  id=decision-0-decisionid  ${decisions[0].decisionID}
    ${decision_date}=  convert_date_for_decision  ${decisions[0].decisionDate}
    Input Text  id=decision-0-decisiondate  ${decision_date}
    Click Element  id=assetHolder-checkBox
    Wait Until Element Is Visible  id=organization-assetholder-name
    Input Text  id=organization-assetholder-name  ${data.assetHolder.name}
    Input Text  id=identifier-assetholder-id  ${data.assetHolder.identifier.id}
    ${items_length}=  Get Length  ${items}
    :FOR  ${item}  IN RANGE  ${items_length}
    \  Log  ${items[${item}]}
    \  Run Keyword If  ${item} > 0  Scroll To And Click Element  xpath=//button[@id="add-item"]
    \  Додати Предмет МП  ${items[${item}]}
    Select From List By Index  id=contact-point-select  1
    Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]
    ${auction_id}=  Get Text  xpath=//div[@data-test-id="tenderID"]
    [Return]  ${auction_id}


Додати предмет МП
    [Arguments]  ${item_data}
    ${item_number}=  Get Element Attribute  xpath=(//div[contains(@class, "asset-item") and not (contains(@class, "__empty__"))])[last()]@class
    ${item_number}=  Set Variable  ${item_number.split('-')[-1]}
    Input Text  xpath=//*[@id="asset-${item_number}-description"]  ${item_data.description}
    Convert Input Data To String  xpath=//*[@id="asset-${item_number}-quantity"]  ${item_data.quantity}
    ${classification_scheme}=  Convert To Lowercase  ${item_data.classification.scheme}
    Select From List By Value  //div[contains(@class, "asset-item-${item_number}")]/descendant::select[@id="classification-scheme"]  ${classification_scheme}
    Click Element  xpath=//*[@id="classification-${item_number}-description"]
    Wait Until Element Is Visible  xpath=//*[@class="modal-title"]
    Input Text  xpath=//*[@placeholder="Пошук по коду"]  ${item_data.classification.id}
    Wait Until Element Is Visible  xpath=//*[@id="${item_data.classification.id}"]
    Scroll To And Click Element  xpath=//*[@id="${item_data.classification.id}"]
    Wait Until Element Is Enabled  xpath=//button[@id="btn-ok"]
    Click Element  xpath=//button[@id="btn-ok"]
    Wait Until Element Is Not Visible  xpath=//*[@class="fade modal"]
    Wait Until Element Is Visible  xpath=//*[@id="unit-${item_number}-code"]
    Select From List By Value  xpath=//*[@id="unit-${item_number}-code"]  ${item_data.unit.code}
    Select From List By Value  xpath=//*[@id="address-${item_number}-countryname"]  ${item_data.address.countryName}
    Scroll To  xpath=//*[@id="address-${item_number}-region"]
    Select From List By Value  xpath=//*[@id="address-${item_number}-region"]  ${item_data.address.region.replace(u' область', u'')}
    Input Text  xpath=//*[@id="address-${item_number}-locality"]  ${item_data.address.locality}
    Input Text  xpath=//*[@id="address-${item_number}-streetaddress"]  ${item_data.address.streetAddress}
    Input Text  xpath=//*[@id="address-${item_number}-postalcode"]  ${item_data.address.postalCode}
    Select From List By Value  id=registration-${item_number}-status  ${item_data.registrationDetails.status}



Додати актив до об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${item_data}
    centrex.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "asset/update")]
    Wait Until Element Is Visible  xpath=//form[@id="asset-form"]
    Scroll To And Click Element  xpath=//button[@id="add-item-to-asset"]
    Run Keyword And Ignore Error  centrex.Додати предмет МП  ${item_data}
    Run Keyword And Ignore Error  centrex.Scroll To And Click Element   id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]



Пошук об’єкта МП по ідентифікатору
    [Arguments]  ${username}  ${tender_uaid}
    Switch Browser  my_alias
    Go To  ${USERS.users['${username}'].homepage}
    Sleep  3
    Закрити Модалку
    Click Element  xpath=//*[@id="h-menu"]/descendant::a[contains(@href, "assets/index")]
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Шукати")]
    Input Text  id=assetssearch-asset_cbd_id  ${tender_uaid}
    Click Element  xpath=//button[contains(text(), "Шукати")]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Element Is Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  20 x  3 s  Run Keywords
    ...  Click Element  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]/../../div[2]/a[contains(@href, "/asset/view")]
    ...  AND  Wait Until Element Is Not Visible  xpath=//button[contains(text(), "Шукати")]  10
    Закрити Модалку
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]  20

Оновити сторінку з об'єктом МП
    [Arguments]  ${username}  ${tender_uaid}
    centrex.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}

Внести зміни в об'єкт МП
    [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
    centrex.Пошук об’єкта МП по ідентифікатору  ${tender_owner}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "asset/update")]
    Wait Until Element Is Visible  xpath=//form[@id="asset-form"]
    Run Keyword If  '${fieldname}' == 'title'  Input Text  id=asset-title  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'description'  Input Text  id=asset-description  ${fieldvalue}
    ...  ELSE  Input Text  xpath=//*[@id="${field_name}"]  ${field_value}
    Scroll To And Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]


Внести зміни в актив об'єкта МП
    [Arguments]  ${username}  ${item_id}  ${tender_uaid}  ${field_name}  ${field_value}
    centrex.Пошук об’єкта МП по ідентифікатору  ${tender_owner}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "asset/update")]
    Wait Until Element Is Visible  xpath=//form[@id="asset-form"]
    ${quantity}=  Convert To String  ${field_value}
    Run Keyword If   '${field_name}' == 'quantity'  Input Text  xpath=//textarea[contains(@data-old-value, "${item_id}")]/../../following-sibling::div/descendant::input[contains(@id, "quantity")]  ${quantity}
    Scroll To And Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]


Завантажити документ для видалення об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}
    centrex.Завантажити документ в об'єкт МП з типом  ${username}  ${tender_uaid}  ${file_path}  cancellationDetails


Завантажити ілюстрацію в об'єкт МП
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  centrex.Завантажити документ в об'єкт МП з типом  ${username}  ${tender_uaid}  ${filepath}  illustration


Завантажити документ в об'єкт МП з типом
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${doc_type}
    centrex.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "asset/update")]
    Wait Until Element Is Visible  xpath=//form[@id="asset-form"]
    Choose File  xpath=(//*[@action="/tender/fileupload"]/input)[last()]  ${file_path}
    Sleep  2
    ${last_input_number}=  Get Element Attribute  xpath=(//select[contains(@class, "document-related-item") and not (contains(@id, "__empty__"))])[last()]@id
    ${last_input_number}=  Set Variable  ${last_input_number.split('-')[1]}
    Input Text  id=document-${last_input_number}-title  ${file_path.split('/')[-1]}
    Select From List By Value  id=document-${last_input_number}-documenttype  ${doc_type}
    Select From List By Label  id=document-${last_input_number}-relateditem  Загальний
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10


Видалити об'єкт МП
    [Arguments]  ${username}  ${tender_uaid}
    centrex.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  id=delete_btn
    Wait Until Element Is Visible  xpath=//div[@class="modal-footer"]
    Click Element  xpath=//button[@data-bb-handler="confirm"]
    Wait Until Element Is Visible  //div[contains(@class,'alert-success')]



Отримати інформацію із об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    ${red}=  Evaluate  "\\033[1;31m"
    Run Keyword If  'title' in '${field}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
    ${value}=  Run Keyword If  '${field}' == 'assetCustodian.identifier.legalName'  Get Text  xpath=//div[@data-test-id="assetCustodian.identifier.legalName"]
    ...  ELSE IF  'assetHolder.identifier.id' in '${field}'  Get Text  //*[@data-test-id="assetHolder.identifier.id"]
    ...  ELSE IF  'assetHolder.identifier.scheme' in '${field}'  Get Text  //*[@data-test-id="assetHolder.identifier.scheme"]
    ...  ELSE IF  'assetHolder.name' in '${field}'  Get Text  //*[@data-test-id="assetHolder.name"]
    ...  ELSE IF  'status' in '${field}'  Get Element Attribute  xpath=//input[@id="asset_status"]@value
    ...  ELSE IF  '${field}' == 'assetID'  Get Text  xpath=//div[@data-test-id="tenderID"]
    ...  ELSE IF  '${field}' == 'description'  Get Text  xpath=//div[@data-test-id="item.description"]
    ...  ELSE IF  '${field}' == 'documents[0].documentType'  Get Text  xpath=//span[@data-test-id="document.type"]
    ...  ELSE IF  'rectificationPeriod' in '${field}'  Get Text  xpath=//div[@data-test-id="rectificationPeriod"]
    ...  ELSE IF  'decisions' in '${field}'  Отримати інформацію про decisions  ${field}
    ...  ELSE IF  'assetCustodian.identifier.id' in '${field}'  Get Text  xpath=(//*[@data-test-id='${field}'])[last()]
    ...  ELSE  Get Text  xpath=//*[@data-test-id='${field}']
    ${value}=  adapt_asset_data  ${field}  ${value}
    [Return]  ${value}


Отримати інформацію з активу об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${object_id}  ${field}
    ${red}=  Evaluate  "\\033[1;31m"
    ${field}=  Set Variable If  '[' in '${field}'  ${field.split('[')[0]}${field.split(']')[1]}  ${field}
    ${value}=  Run Keyword If
    ...  '${field}' == 'classification.scheme'  Get Text  //*[contains(text(),'${object_id}')]/ancestor::div[2]/descendant::div[@data-test-id="item.classification.scheme"]
    ...  ELSE IF  '${field}' == 'additionalClassifications.description'  Get Text  xpath=//*[contains(text(),'${object_id}')]/ancestor::div[2]/descendant::*[text()='PA01-7']/following-sibling::span
    ...  ELSE IF  'description' in '${field}'  Get Text  //div[contains(text(),'${object_id}')]/ancestor::div[contains(@class, "item-inf_txt")]/descendant::*[@data-test-id="asset.item.${field}"]
    ...  ELSE IF  'registrationDetails.status' in '${field}'  Get Text  //div[contains(text(),'${object_id}')]/ancestor::div[contains(@class, "item-inf_txt")]/descendant::*[@data-test-id="item.address.status"]
    ...  ELSE  Get Text  //div[contains(text(),'${object_id}')]/ancestor::div[contains(@class, "item-inf_txt")]/descendant::*[@data-test-id="item.${field}"]
    ${value}=  adapt_data  ${field}  ${value}
    [Return]  ${value}


Отримати кількість активів в об'єкті МП
  [Arguments]  ${username}  ${tender_uaid}
  centrex.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
  ${number_of_items}=  Get Matching Xpath Count  xpath=//div[@data-test-id="asset.item.description"]
  ${number_of_items}=  Convert To Integer  ${number_of_items}
  [Return]  ${number_of_items}


Отримати інформацію про decisions
  [Arguments]  ${field}
  ${index}=  Set Variable  ${field.split('[')[1].split(']')[0]}
  ${index}=  Convert To Integer  ${index}
  ${value}=  Run Keyword If  'title' in '${field}'  Get Text  xpath=(//div[@data-test-id="asset.decision.title"])["${index + 1}"]
  ...  ELSE IF  'decisionDate' in '${field}'  Get Text  xpath=(//div[@data-test-id="asset.decision.decisionDate"])["${index + 1}"]
  ...  ELSE IF  'decisionID' in '${field}'  Get Text  xpath=(//div[@data-test-id="asset.decision.decisionID"])["${index + 1}"]
  [Return]  ${value}


############################################## ЛОТИ #######################################

Створити лот
  [Arguments]  ${username}  ${tender_data}  ${asset_uaid}
  centrex.Пошук об’єкта МП по ідентифікатору  ${username}  ${asset_uaid}
  Click Element  xpath=//a[contains(@href, "lot/create?asset")]
  ${decision_date}=  convert_date_for_decision  ${tender_data.data.decisions[0].decisionDate}
  Input Text   name=Lot[decisions][0][decisionDate]   ${decision_date}
  Input Text   name=Lot[decisions][0][decisionID]   ${tender_data.data.decisions[0].decisionID}
  Click Element  name=simple_submit
  Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]  20
  ${lot_id}=  Get Text  xpath=//div[@data-test-id="lotID"]
  [Return]  ${lot_id}


Заповнити дані для першого аукціону
  [Arguments]  ${username}  ${tender_uaid}  ${auction}
  ${value_amount}=  Convert To String  ${auction.value.amount}
  ${minimalStep}=  Convert To String  ${auction.minimalStep.amount}
  ${guarantee}=  Convert To String  ${auction.guarantee.amount}
  ${registrationFee}=  Convert To String  ${auction.registrationFee.amount}
  centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href, "lot/update")]
  Wait Until Element Is Visible  id=auctions-checkBox
  Click Element  id=auctions-checkBox
  Wait Until Element Is Visible  id=value-value-0-amount
  Input Text  name=Lot[auctions][0][value][amount]  ${value_amount}
  Input Text  name=Lot[auctions][0][minimalStep][amount]  ${minimalStep}
  Input Text  name=Lot[auctions][0][guarantee][amount]  ${guarantee}
  Input Date Auction  name=Lot[auctions][0][auctionPeriod][startDate]  ${auction.auctionPeriod.startDate}


Заповнити дані для другого аукціону
    [Arguments]  ${auction}
    ${tenderingDuration}=  convert_period_date  ${auction.tenderingDuration}
    Input Text  name=Lot[auctions][1][tenderingDuration]  ${tenderingDuration}
    Input Text  name=Lot[auctions][2][auctionParameters][dutchSteps]  99
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//a[contains(@href, "lot/update")]
    Click Element  name=verification_submit
    Wait Until Element Is Visible  xpath=//*[@data-test-id="status"][contains(text(), "Перевірка доступності об’єкту")]



Додати умови проведення аукціону
  [Arguments]  ${username}  ${auction}  ${index}  ${tender_uaid}
  Run Keyword If  ${index} == 0  Заповнити дані для першого аукціону  ${username}  ${tender_uaid}  ${auction}
  Run Keyword If  ${index} == 1  Заповнити дані для другого аукціону  ${auction}



Пошук лоту по ідентифікатору
    [Arguments]  ${username}  ${tender_uaid}
    Switch Browser  my_alias
    Go To  ${USERS.users['${username}'].homepage}
    Sleep  3
    Закрити Модалку
    Click Element  xpath=//a[contains(@href, "lots/index")][contains(text(), "Повідомлення")]
    Wait Until Element Is Visible  xpath=//button[@data-test-id="search"]
    Input Text  id=lotssearch-lot_cbd_id  ${tender_uaid}
    Click Element  xpath=//button[@data-test-id="search"]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Element Is Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  20 x  3 s  Run Keywords
    ...  Click Element  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]/../following-sibling::div/a
    ...  AND  Wait Until Element Is Not Visible  xpath=//button[contains(text(), "Шукати")]  10
    Закрити Модалку
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]  20


Оновити сторінку з лотом
    [Arguments]  ${username}  ${tender_uaid}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}


Отримати інформацію із лоту
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    ${red}=  Evaluate  "\\033[1;31m"
    Run Keyword If  'title' in '${field}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
    ${value}=  Run Keyword If  '${field}' == 'lotCustodian.identifier.legalName'  Get Text  xpath=//div[@data-test-id="procuringEntity.name"]
    ...  ELSE IF  'lotHolder.identifier.id' in '${field}'  Get Text  //*[@data-test-id="assetHolder.identifier.id"]
    ...  ELSE IF  'lotCustodian.identifier.scheme' in '${field}'  Get Text  //*[@data-test-id='lotCustodian.identifier.scheme']
    ...  ELSE IF  'lotCustodian.identifier.id' in '${field}'  Get Text  //*[@data-test-id='lotCustodian.identifier.id']
    ...  ELSE IF  'lotHolder.identifier.scheme' in '${field}'  Get Text  //*[@data-test-id="assetHolder.identifier.scheme"]
    ...  ELSE IF  'lotHolder.name' in '${field}'  Get Text  //*[@data-test-id="assetHolder.name"]
    ...  ELSE IF  '${field}' == 'status'  Get Text  xpath=//div[@data-test-id="status"]
    ...  ELSE IF  '${field}' == 'assetID'  Get Text  xpath=//div[@data-test-id="tenderID"]
    ...  ELSE IF  '${field}' == 'description'  Get Text  xpath=//div[@data-test-id="item.description"]
    ...  ELSE IF  '${field}' == 'documents[0].documentType'  Get Text  xpath=//a[contains(@href, "info/ssp_details")]/../following-sibling::div[1]
    ...  ELSE IF  'decisions' in '${field}'  Отримати інформацію про lot decisions  ${field}
    ...  ELSE IF  'rectificationPeriod' in '${field}'  Get Text  xpath=//div[@data-test-id="rectificationPeriod"]
    ...  ELSE IF  'assets' in '${field}'  Get Element Attribute  xpath=//input[@name="asset_id"]@value
    ...  ELSE IF  'auctions' in '${field}'  Отримати інформацію про lot auctions  ${field}
    ...  ELSE  Get Text  xpath=//*[@data-test-id='${field.replace('lotCustodian', 'procuringEntity')}']
    ${value}=  adapt_asset_data  ${field}  ${value}
    [Return]  ${value}


Отримати інформацію про lot auctions
    [Arguments]  ${field}
    ${lot_index}=  Set Variable  ${field.split('[')[1].split(']')[0]}
    ${lot_index}=  Convert To Integer  ${lot_index}
    ${value}=  Run Keyword If  'procurementMethodType' in '${field}'  Get Element Attribute  xpath=//input[@name="auction.${lot_index}.procurementMethodType"]@value
    ...  ELSE IF  'value.amount' in '${field}'  Get Text  xpath=(//div[contains(text(), "Початкова ціна продажу лота")]/following-sibling::div)[${lot_index + 1}]
    ...  ELSE IF  'minimalStep.amount' in '${field}'  Get Text  xpath=(//div[contains(text(), "Крок аукціону")]/following-sibling::div)[${lot_index + 1}]
    ...  ELSE IF  'guarantee.amount' in '${field}'  Get Text  xpath=(//div[contains(text(), "Гарантійний внесок")]/following-sibling::div)[${lot_index + 1}]
    ...  ELSE IF  'tenderingDuration' in '${field}'  Get Text  xpath=(//div[contains(text(), "Період на подачу пропозицій")]/following-sibling::div)[${lot_index}]
    ...  ELSE IF  'auctionPeriod.startDate' in '${field}'  Get Text  xpath=(//div[contains(text(), "Період початку першого аукціону циклу")]/following-sibling::div)[${lot_index + 1}]
    ...  ELSE IF  'status' in '${field}'  Get Text  xpath=(//div[@data-test-id="auction.status"])[${lot_index + 1}]
    ...  ELSE IF  'tenderAttempts' in '${field}'  Get Text  xpath=(//span[@data-test-id="auction.tenderAttempts"])[${lot_index + 1}]
    ...  ELSE IF  'registrationFee.amount' in '${field}'  Get Text  xpath=(//div[@data-test-id="auction.registrationFee.amount"])[${lot_index + 1}]

    ${value}=  adapt_lot_data  ${field}  ${value}
    [Return]  ${value}



Отримати інформацію з активу лоту
    [Arguments]  ${username}  ${tender_uaid}  ${object_id}  ${field}
    ${red}=  Evaluate  "\\033[1;31m"
    ${field}=  Set Variable If  '[' in '${field}'  ${field.split('[')[0]}${field.split(']')[1]}  ${field}
    ${value}=  Run Keyword If
    ...  '${field}' == 'classification.scheme'  Get Text  //*[contains(text(),'${object_id}')]/ancestor::div[2]/following-sibling::div[2]/div/span
    ...  ELSE IF  '${field}' == 'additionalClassifications.description'  Get Text  xpath=//*[contains(text(),'${object_id}')]/ancestor::div[2]/descendant::*[text()='PA01-7']/following-sibling::span
    ...  ELSE IF  'description' in '${field}'  Get Text  //b[contains(text(),"${object_id}")]
    ...  ELSE IF  'classification.id' in '${field}'  Get Text  //b[contains(text(),"${object_id}")]/../../following-sibling::div[2]/descendant::div[@data-test-id="item.classification"]
    ...  ELSE IF  'unit.name' in '${field}' or 'quantity' in '${field}'  Get Text  //b[contains(text(),"${object_id}")]/../../following-sibling::div[3]/descendant::div[@data-test-id="item.classification"]
    ...  ELSE IF  'registrationDetails.status' in '${field}'  Get Text  //b[contains(text(),"${object_id}")]/../../following-sibling::div[4]/descendant::div[@data-test-id="item.classification"]
    ...  ELSE  Get Text  //div[contains(text(),'${object_id}')]/ancestor::div[contains(@class, "item-inf_txt")]/descendant::*[@data-test-id="item.${field}"]
    ${value}=  adapt_lot_data  ${field}  ${value}
    [Return]  ${value}


Отримати інформацію про lot decisions
  [Arguments]  ${field}
  ${index}=  Set Variable  ${field.split('[')[1].split(']')[0]}
  ${index}=  Convert To Integer  ${index}
  ${value}=  Run Keyword If  'title' in '${field}'  Get Text  xpath=(//div[@data-test-id="decision.title"])[${index + 1}]
  ...  ELSE IF  'decisionDate' in '${field}'  Get Text  xpath=(//div[@data-test-id="decision.decisionDate"])[${index + 1}]
  ...  ELSE IF  'decisionID' in '${field}'  Get Text  xpath=(//div[@data-test-id="decision.decisionID"])[${index + 1}]
  [Return]  ${value}


Завантажити ілюстрацію в лот
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  centrex.Завантажити документ в лот з типом  ${username}  ${tender_uaid}  ${filepath}  illustration


Завантажити документ в лот з типом
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${doc_type}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "lot/update")]
    Wait Until Element Is Visible  id=decision-title
    Choose File  xpath=(//*[@action="/tender/fileupload"]/input)[last()]  ${file_path}
    Sleep  2
    ${last_input_number}=  Get Element Attribute  xpath=(//input[contains(@class, "document-title") and not (contains(@id, "__empty__"))])[last()]@id
    ${last_input_number}=  Set Variable  ${last_input_number.split('-')[1]}
    Input Text  id=document-${last_input_number}-title  ${file_path.split('/')[-1]}
    Select From List By Value  id=document-${last_input_number}-level  lot
    Select From List By Value  id=document-${last_input_number}-documenttype  ${doc_type}
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10


Завантажити документ в умови проведення аукціону
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${doc_type}  ${index}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "lot/update")]
    Wait Until Element Is Visible  id=decision-title
    Choose File  xpath=(//*[@action="/tender/fileupload"]/input)[last()]  ${file_path}
    Sleep  2
    ${new_index}=  Convert To Integer  ${index}
    ${new_index}=  Convert To String  ${new_index + 1}
    ${last_input_number}=  Get Element Attribute  xpath=(//input[contains(@class, "document-title") and not (contains(@id, "__empty__"))])[last()]@id
    ${last_input_number}=  Set Variable  ${last_input_number.split('-')[1]}
    Input Text  xpath=(//input[@id="document-${last_input_number}-title"])[last()]  ${file_path.split('/')[-1]}
    Select From List By Label  xpath=(//select[@id="document-${last_input_number}-level"])[last()]  Аукціон № ${new_index}
    Select From List By Value  xpath=(//select[@id="document-${last_input_number}-documenttype"])[last()]  ${doc_type}
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10


Внести зміни в лот
    [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "lot/update")]
    Wait Until Element Is Visible  id=decision-title
    Run Keyword If  '${fieldname}' == 'title'  Input Text  id=lot-title  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'description'  Input Text  id=lot-description  ${fieldvalue}
    ...  ELSE  Input Text  xpath=//*[@id="${field_name}"]  ${field_value}
    Scroll To And Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]


Внести зміни в актив лоту
  [Arguments]  ${username}  ${item_id}  ${tender_uaid}  ${field_name}  ${field_value}
  centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href, "lot/update")]
  Wait Until Element Is Visible  id=decision-title
  ${quantity}=  Convert To String  ${field_value}
  Run Keyword If   '${field_name}' == 'quantity'  Input Text  xpath=//input[contains(@value, "${item_id}")]/../../following-sibling::div[2]/descendant::input[contains(@name, "quantity")]  ${quantity}
  Scroll To And Click Element  //*[@name="simple_submit"]
  Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]


Внести зміни в умови проведення аукціону
    [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}  ${index}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "lot/update")]
    Wait Until Element Is Visible  id=decision-title
    Run Keyword If  '${fieldname}' == 'value.amount'  Input Amount  name=Lot[auctions][0][value][amount]  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'minimalStep.amount'  Input Amount  name=Lot[auctions][0][minimalStep][amount]  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'guarantee.amount'  Input Amount  name=Lot[auctions][0][guarantee][amount]  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'registrationFee.amount'  Input Amount  name=Lot[auctions][0][registrationFee][amount]  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'auctionPeriod.startDate'  Input Date Auction  name=Lot[auctions][0][auctionPeriod][startDate]  ${fieldvalue}
    Scroll To And Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]


Завантажити документ для видалення лоту
  [Arguments]  ${username}  ${tender_uaid}  ${file_path}
  centrex.Завантажити документ в лот з типом  ${username}  ${tender_uaid}  ${filepath}  cancellationDetails


Видалити лот
    [Arguments]  ${username}  ${tender_uaid}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  id=delete_btn
    Wait Until Element Is Visible  //button[@data-bb-handler="confirm"]
    Click Element  //button[@data-bb-handler="confirm"]
    Wait Until Element Is Visible  xpath=//div[contains(@class, "alert-success")]


##################################################################################
Input Amount
    [Arguments]  ${locator}  ${value}
    ${value}=  Convert To String  ${value}
    Clear Element Text  ${locator}
    Input Text  ${locator}  ${value}


Input Date Auction
    [Arguments]  ${locator}  ${value}
    ${value}=  convert_date_for_auction  ${value}
    Clear Element Text  ${locator}
    Input Text  ${locator}  ${value}



Отримати документ
    [Arguments]  ${username}  ${TENDER['TENDER_UAID']}  ${doc_id}
    ${file_name}=  Get Text  xpath=//a[contains(text(), '${doc_id}')]
    ${url}=  Get Element Attribute  xpath=//a[contains(text(), '${doc_id}')]@href
    download_file  ${url}  ${file_name}  ${OUTPUT_DIR}
    [Return]  ${file_name}


Scroll
    [Arguments]  ${locator}
    Execute JavaScript    window.scrollTo(0,0)


Scroll To
    [Arguments]  ${locator}
    ${y}=  Get Vertical Position  ${locator}
    Execute JavaScript    window.scrollTo(0,${y-100})


Scroll To And Click Element
    [Arguments]  ${locator}
    ${y}=  Get Vertical Position  ${locator}
    Execute JavaScript    window.scrollTo(0,${y-100})
    Click Element  ${locator}


Закрити Модалку
    ${status}=  Run Keyword And Return Status  Wait Until Element Is Visible  xpath=//button[@data-dismiss="modal"]  5
    Run Keyword If  ${status}  Wait Until Keyword Succeeds  5 x  1 s  Run Keywords
    ...  Click Element  xpath=//button[@data-dismiss="modal"]
    ...  AND  Wait Until Element Is Not Visible  xpath=//*[contains(@class, "modal-backdrop")]


Adapt And Select By Value
    [Arguments]  ${locator}  ${value}
    ${value}=  Convert To String  ${value}
    ${value}=  adapted_dictionary  ${value}
    Select From List By Value  ${locator}  ${value}


Convert Input Data To String
    [Arguments]  ${locator}  ${value}
    ${value}=  Convert To String  ${value}
    Input Text  ${locator}  ${value}


Get Data
    [Arguments]  ${tender_data}
    [Return]  ${tender_data.data}


Close Sidebar
    Click Element  xpath=//*[@id="slidePanelToggle"]


Wait For Document Upload
    Wait Until Keyword Succeeds  30 x  5 s  Run Keywords
    ...  Refresh Page
    ...  AND  Run Keyword And Ignore Error  Click Element  xpath=//*[@data-test-id="sidebar.edit"]
    ...  AND  Wait Until Element Is Visible  xpath=//*[@id="auction-form"]

Select From List By Converted Value
    [Arguments]  ${locator}  ${value}
    ${converted_value}=  Convert To String  ${value}
    Select From List By Value  ${locator}  ${converted_value}


Compare Number Elements
    [Arguments]  ${n_items}
    ${items}=  Get Matching Xpath Count  xpath=//div[@data-test-id="item.description"]
    ${actual_items}=  Convert To Integer  ${items}
    Should Be Equal  ${actual_items}  ${n_items + 1}
