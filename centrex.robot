*** Settings ***
Library  Selenium2Library
Library  BuiltIn
Library  Collections
Library  String
Library  DateTime
Library  centrex_service.py
Library  op_robot_tests.tests_files.service_keywords

*** Variables ***
${host}  http://test-eauction.centrex.com.ua

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
    ...  Авторизуватися  ${username}
    ...  AND  Run Keyword And Ignore Error  Закрити Модалку


Підготувати дані для оголошення тендера
    [Arguments]  ${username}  ${initial_tender_data}  ${role}
    ${tender_data}=  prepare_tender_data  ${role}  ${initial_tender_data}
    [Return]  ${tender_data}


Авторизуватися
    [Arguments]  ${username}
    Click Element  xpath=//*[contains(@href,"/login")]
    Wait Until Element Is Visible  xpath=//button[@name="login-button"]
    Input Text  xpath=//input[@id="loginform-username"]  ${USERS.users['${username}'].login}
    Input Text  xpath=//input[@id="loginform-password"]  ${USERS.users['${username}'].password}
    Click Element  xpath=//button[@name="login-button"]


###############################################################################################################
########################################### ASSETS ############################################################
###############################################################################################################

Створити об'єкт МП
    [Arguments]  ${username}  ${tender_data}
    ${decisions}=   Get From Dictionary   ${tender_data.data}   decisions
    ${items}=  Get From Dictionary  ${tender_data.data}  items
    Click Element  xpath=//button[@data-target="#toggleRight"]
    Wait Until Element Is Visible  xpath=//nav[@id="toggleRight"]/descendant::a[contains(@href, "/assets/index")]
    Click Element  xpath=//nav[@id="toggleRight"]/descendant::a[contains(@href, "/assets/index")]
    Click Element  xpath=//a[contains(@href, "/buyer/asset/create")]
    Input Text  id=asset-title  ${tender_data.data.title}
    Input Text  id=asset-description  ${tender_data.data.description}
    Input Text  id=decision-0-title  ${decisions[0].title}
    Input Text  id=decision-0-decisionid  ${decisions[0].decisionID}
    ${decision_date}=  Convert Date  ${decisions[0].decisionDate}  date_format=%Y-%m-%d  result_format=%d/%m/%Y
    Input Text  id=decision-0-decisiondate  ${decision_date}
    Click Element  id=assetHolder-checkBox
    Wait Until Element Is Visible  id=organization-assetholder-name
    Input Text  id=organization-assetholder-name  ${tender_data.data.assetHolder.name}
    Input Text  id=identifier-assetholder-id  ${tender_data.data.assetHolder.identifier.id}
    ${items_length}=  Get Length  ${items}
    :FOR  ${item}  IN RANGE  ${items_length}
    \  Run Keyword If  ${item} > 0  Scroll To And Click Element  xpath=//button[@id="add-item"]
    \  Додати предмет МП  ${items[${item}]}
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
    Click Element  xpath=//*[@id="classification-${item_number}-description"]
    Wait Until Element Is Visible  xpath=//*[@class="modal-title"]
    Input Text  xpath=//*[@placeholder="Пошук по коду"]  ${item_data.classification.id}
    Wait Until Element Is Visible  xpath=//*[contains(@id,"${item_data.classification.id}")][last()]
    Scroll To And Click Element  xpath=//*[contains(@id,"${item_data.classification.id}")][last()]
    Wait Until Element Is Enabled  xpath=//button[@id="btn-ok"]
    Click Element  xpath=//button[@id="btn-ok"]
    Wait Until Element Is Not Visible  xpath=//*[@class="fade modal"]
    Wait Until Element Is Visible  xpath=//*[@id="unit-${item_number}-code"]
    Select From List By Value  xpath=//*[@id="unit-${item_number}-code"]  ${item_data.unit.code}
    Select From List By Value  xpath=//*[@id="address-${item_number}-countryname"]  ${item_data.address.countryName}
    Scroll To  xpath=//*[@id="address-${item_number}-region"]
    Wait Until Page Contains Element  xpath=//*[@id="address-${item_number}-region"]/option[text()='місто Київ']
    Select From List By Label  xpath=//*[@id="address-${item_number}-region"]  ${item_data.address.region}
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
    Wait until element is visible  xpath=//a[contains(text(), "м.Приватизац")]
    Click Element  xpath=//a[contains(text(), "м.Приватизац")]
    Wait Until Element Is Visible  xpath=//*[@id="h-menu"]/descendant::a[contains(@href, "assets/index")]
    Click Element  xpath=//*[@id="h-menu"]/descendant::a[contains(@href, "assets/index")]
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Шукати")]
    Wait Until Keyword Succeeds  40 x  5 s  Run Keywords
    ...  Input Text  id=assetssearch-asset_cbd_id  ${tender_uaid}
    ...  AND  Click Element  xpath=//button[contains(text(), "Шукати")]
    ...  AND  Wait Until Element Is Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  10 x  500 ms  Xpath Should Match X Times  //div[@class="search-result_article"]  1
    Click Element  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]/../../div[2]/a[contains(@href, "/asset/view")]
    Wait Until Page Does Not Contain Element  xpath=//button[contains(text(), "Шукати")]  10
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]
    Синхронізуватися із ЦБД


Синхронізуватися із ЦБД
    ${url}=  Get Location
    Run Keyword If  'view' not in '${url}'  Click Element  xpath=//div[@class="mk-slide-panel_toggle"]
    Go To  ${url.replace('view', 'json').replace('award', 'json').replace('buyer/', '').replace('seller/', '')}
    Go To  ${url}


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
    centrex.Пошук об’єкта МП по ідентифікатору  ${tender_owner}  ${tender_uaid}
    Click Element  id=delete-asset
    Wait Until Element Is Visible  id=form-delete-asset
    Choose File  name=FileUpload[file][]  ${file_path}
    Wait Until Element Is Visible  xpath=//input[contains(@name, "title")]
    Click Element  xpath=//form[@id="form-delete-asset"]/descendant::button[contains(text(), "Видалити об’єкт")]
    Wait Until Element Is Visible  //div[contains(@class,'alert-success')]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Синхронізуватися із ЦБД
    ...  AND  Wait Until Page Contains  Об’єкт виключено  20


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
    ...  Синхронізуватися із ЦБД
    ...  AND  Page Should Not Contain  Документ завантажується...


Видалити об'єкт МП
    [Arguments]  ${username}  ${tender_uaid}
    Log  Необхідні дії було виконано у "Завантажити документ для видалення об'єкта МП"


Отримати інформацію із об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    Синхронізуватися із ЦБД
    Run Keyword If  'title' in '${field}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
    ${value}=  Run Keyword If  '${field}' == 'assetCustodian.identifier.legalName'  Get Text  xpath=//div[@data-test-id="assetCustodian.identifier.legalName"]
    ...  ELSE IF  'assetHolder.identifier.id' in '${field}'  Get Text  //*[@data-test-id="assetHolder.identifier.id"]
    ...  ELSE IF  'assetHolder.identifier.scheme' in '${field}'  Get Text  //*[@data-test-id="assetHolder.identifier.scheme"]
    ...  ELSE IF  'assetHolder.name' in '${field}'  Get Text  //*[@data-test-id="assetHolder.name"]
    ...  ELSE IF  'status' in '${field}'  Пошук статуса із об'єкта МП
    ...  ELSE IF  '${field}' == 'assetID'  Get Text  xpath=//div[@data-test-id="tenderID"]
    ...  ELSE IF  '${field}' == 'description'  Get Text  xpath=//div[@data-test-id="item.description"]
#    ...  ELSE IF  '${field}' == 'description'  Пошук опису із об'єкта МП  ${field}
    ...  ELSE IF  '${field}' == 'documents[0].documentType'  Get Text  xpath=//span[@data-test-id="document.type"]
    ...  ELSE IF  'rectificationPeriod' in '${field}'  Get Text  xpath=//div[@data-test-id="rectificationPeriod"]
    ...  ELSE IF  'decisions' in '${field}'  Отримати інформацію про decisions  ${field}
    ...  ELSE IF  'assetCustodian.identifier.id' in '${field}'  Get Text  xpath=(//*[@data-test-id='${field}'])[last()]
    ...  ELSE  Get Text  xpath=//*[@data-test-id='${field}']
    ${value}=  adapt_asset_data  ${field}  ${value}
    [Return]  ${value}

#Пошук опису із об'єкта МП
#    [Arguments]  ${field}
#    Run keyword if  "Відображення зміненого опису об'єкта МП" == "${TEST NAME}"  Wait until keyword succeeds  40 x  10 s  Run Keywords
#        ...  Reload Page
#        ...  AND  Page Should Contain element  xpath=//div[@data-test-id="item.description"][contains(text(), "${field}")]
#    ${value}=  Get Text  xpath=//div[@data-test-id="item.description"]
#    [Return]  ${value}

Пошук статуса із об'єкта МП
    Run keyword if  "Відображення статусу 'Виключено з переліку'" == "${TEST NAME}"  Wait until keyword succeeds  40 x  10 s  Run Keywords
        ...  Reload Page
        ...  AND  Page Should Contain element  xpath=//div[@data-test-id="status"][contains(text(), "Об’єкт виключено")]
    ${value}=  Get Element Attribute  xpath=//input[@id="asset_status"]@value
    [Return]  ${value}

Отримати інформацію з активу об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${object_id}  ${field}
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
    Click Element  xpath=//a[contains(text(),'Створити інформаційне повідомлення')]
    ${decision_date}=  Convert Date  ${tender_data.data.decisions[0].decisionDate}  date_format=%Y-%m-%d  result_format=%d/%m/%Y
    Input Text   name=Lot[decisions][0][decisionDate]   ${decision_date}
    Input Text   name=Lot[decisions][0][decisionID]   ${tender_data.data.decisions[0].decisionID}
    Execute Javascript  $("input[name='lot_procurementMethodDetails']").val('${period_intervals.lots.accelerator}');
    Click Element  name=simple_submit
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]  20
    ${lot_id}=  Get Text  xpath=//div[@data-test-id="lotID"]
    [Return]  ${lot_id}


Заповнити дані для першого аукціону
    [Arguments]  ${username}  ${tender_uaid}  ${auction}
    ${value_amount}=  Convert To String  ${auction.value.amount}
    ${minimalStep}=  Convert To String  ${auction.minimalStep.amount}
    ${guarantee}=  Convert To String  ${auction.guarantee.amount}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "lot/update")]
    Wait Until Element Is Visible  xpath=//input[@id='auctions-checkBox']
    Click Element  xpath=//input[@id='auctions-checkBox']
    Wait Until Element Is Visible  id=value-value-0-amount
    Input Text  name=Lot[auctions][0][value][amount]  ${value_amount}
    ${tax}=  Set Variable If  ${auction.value.valueAddedTaxIncluded}  1  0
    Select From List By Value   name=Lot[auctions][0][value][valueAddedTaxIncluded]  ${tax}
    Wait Until Element Is Visible  xpath=//input[@id='value-minimalstep-0-amount']
    Input Text  xpath=//input[@id='value-minimalstep-0-amount']  ${minimalStep}
    Input Text  name=Lot[auctions][0][guarantee][amount]  ${guarantee}
    Input Date Auction  name=Lot[auctions][0][auctionPeriod][startDate]  ${auction.auctionPeriod.startDate}
    Input Text  name=Lot[auctions][0][bankAccount][bankName]  ${auction.bankAccount.bankName}
    ${bank_id}=  adapt_edrpou  ${auction.bankAccount.accountIdentification[0].id}
    Input Text  name=Lot[auctions][0][bankAccount][accountIdentification][0][id]  ${bank_id}
    Input Text  name=Lot[auctions][0][bankAccount][accountIdentification][1][id]  123456
    Input Text  name=Lot[auctions][0][bankAccount][accountIdentification][2][id]  1234567890


Заповнити дані для другого аукціону
    [Arguments]  ${auction}
    ${duration}=  convert_duration  ${auction.tenderingDuration}
    Input Text  name=Lot[auctions][1][tenderingDuration]  ${duration}
    Input Text  name=Lot[auctions][2][auctionParameters][dutchSteps]  20
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  name=verification_submit
    Click Element  name=verification_submit
    Wait Until Element Is Visible  xpath=//*[@data-test-id="status"][contains(text(), "Перевірка доступності об’єкту")]


Додати умови проведення аукціону
    [Arguments]  ${username}  ${auction}  ${index}  ${tender_uaid}
    Run Keyword If  ${index} == 0  Заповнити дані для першого аукціону  ${username}  ${tender_uaid}  ${auction}
    ...  ELSE  Заповнити дані для другого аукціону  ${auction}


Пошук лоту по ідентифікатору
    [Arguments]  ${username}  ${tender_uaid}
    Switch Browser  my_alias
    Go To  ${USERS.users['${username}'].homepage}
    Закрити Модалку
    Wait until element is visible  xpath=//a[contains(text(), "м.Приватизац")]
    Click Element  xpath=//a[contains(text(), "м.Приватизац")]
    Wait Until Element Is Visible  xpath=//a[contains(@href, "lots/index")][contains(text(), "Інформаційні повідомлення")]
    Click Element  xpath=//a[contains(@href, "lots/index")][contains(text(), "Інформаційні повідомлення")]
    Wait Until Element Is Visible  xpath=//button[@data-test-id="search"]
    Wait Until Keyword Succeeds  40 x  5 s  Run Keywords
    ...  Input Text  id=lotssearch-lot_cbd_id  ${tender_uaid}
    ...  AND  Click Element  xpath=//button[@data-test-id="search"]
    ...  AND  Wait Until Element Is Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  10 x  500 ms  Xpath Should Match X Times  //div[@class="search-result"]  1
    Click Element  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]/../following-sibling::div/a
    Wait Until Page Does Not Contain Element  xpath=//button[contains(text(), "Шукати")]  10
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]
    Синхронізуватися із ЦБД


Оновити сторінку з лотом
    [Arguments]  ${username}  ${tender_uaid}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}


Отримати інформацію із лоту
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    Run Keyword If  'title' in '${field}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
    Run Keyword If  '${field}' == 'status' or 'auctionPeriod.startDate' in '${field}'  Reload Page
    ${value}=  Run Keyword If  '${field}' == 'lotCustodian.identifier.legalName'  Get Text  xpath=//div[@data-test-id="procuringEntity.name"]
    ...  ELSE IF  'lotHolder.identifier.id' in '${field}'  Get Text  //*[@data-test-id="assetHolder.identifier.id"]
    ...  ELSE IF  'lotCustodian.identifier.scheme' in '${field}'  Get Text  //*[@data-test-id='lotCustodian.identifier.scheme']
    ...  ELSE IF  'lotCustodian.identifier.id' in '${field}'  Get Text  //*[@data-test-id='lotCustodian.identifier.id']
    ...  ELSE IF  'lotHolder.identifier.scheme' in '${field}'  Get Text  //*[@data-test-id="assetHolder.identifier.scheme"]
    ...  ELSE IF  'lotHolder.name' in '${field}'  Get Text  //*[@data-test-id="assetHolder.name"]
    ...  ELSE IF  '${field}' == 'status'  Get Text  xpath=//div[@data-test-id="status"]
    ...  ELSE IF  'relatedProcessID' in '${field}'  Get Element Attribute  xpath=//*[@id="asset-id"]@value
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
    Run Keyword If  'auctionID' in '${field}'  Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Contain Element  xpath=//div[@data-test-id="status"][contains(text(), "Аукціон")]
    ${value}=  Run Keyword If  'procurementMethodType' in '${field}'  Get Element Attribute  xpath=//input[@name="auction.${lot_index}.procurementMethodType"]@value
    ...  ELSE IF  'value.amount' in '${field}'  Get Text  xpath=(//div[contains(text(), "Початкова ціна продажу")]/following-sibling::div)[${lot_index + 1}]
    ...  ELSE IF  'minimalStep.amount' in '${field}'  Get Text  xpath=(//div[contains(text(), "Крок аукціону")]/following-sibling::div)[${lot_index + 1}]
    ...  ELSE IF  'guarantee.amount' in '${field}'  Get Text  xpath=(//div[contains(text(), "Гарантійний внесок")]/following-sibling::div)[${lot_index + 1}]
    ...  ELSE IF  'tenderingDuration' in '${field}'  Get Text  xpath=(//div[contains(text(), "Період на подачу пропозицій")]/following-sibling::div)[${lot_index}]
    ...  ELSE IF  'auctionPeriod.startDate' in '${field}'  Get Text  xpath=(//div[contains(text(), "Період початку першого аукціону циклу")]/following-sibling::div)[${lot_index + 1}]
    ...  ELSE IF  'status' in '${field}'  Get Text  xpath=(//div[@data-test-id="auction.status"])[${lot_index + 1}]
    ...  ELSE IF  'tenderAttempts' in '${field}'  Get Text  xpath=(//span[@data-test-id="auction.tenderAttempts"])[${lot_index + 1}]
    ...  ELSE IF  'auctionID' in '${field}'  Get Text  xpath=//div[contains(text(), "Ідентифікатор аукціону")]/following-sibling::div/a
    ${value}=  adapt_lot_data  ${field}  ${value}
    [Return]  ${value}


Отримати інформацію з активу лоту
    [Arguments]  ${username}  ${tender_uaid}  ${object_id}  ${field}
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
    ...  ELSE IF  'decisionDate' in '${field}'  Get Text  xpath=//div[@data-test-id="decision.decisionDate"]
    ...  ELSE IF  'decisionID' in '${field}'  Get Text  xpath=(//div[@data-test-id="decision.decisionID"])[${index + 1}]
    [Return]  ${value}


Завантажити ілюстрацію в лот
    [Arguments]  ${username}  ${tender_uaid}  ${filepath}
    centrex.Завантажити документ в лот з типом  ${username}  ${tender_uaid}  ${filepath}  illustration


Обрати файл з необхідним типом
    [Arguments]  ${file_path}  ${doc_type}
    Choose File  xpath=(//*[@action="/tender/fileupload"]/input)[last()]  ${file_path}
    Sleep  2
    ${last_input_number}=  Get Element Attribute  xpath=(//input[contains(@class, "document-title") and not (contains(@id, "__empty__"))])[last()]@id
    ${last_input_number}=  Set Variable  ${last_input_number.split('-')[1]}
    Input Text  id=document-${last_input_number}-title  ${file_path.split('/')[-1]}
    Select From List By Value  id=document-${last_input_number}-level  lot
    Select From List By Value  id=document-${last_input_number}-documenttype  ${doc_type}


Завантажити документ в лот з типом
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${doc_type}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "lot/update")]
    Wait Until Element Is Visible  xpath=(//input[@id='decision-title'])[1]
    centrex.Обрати файл з необхідним типом  ${filepath}  clarifications
    centrex.Обрати файл з необхідним типом  ${filepath}  ${doc_type}
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Синхронізуватися із ЦБД
    ...  AND  Page Should Not Contain  Документ завантажується...



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
    Select From List By Value  xpath=(//select[@id="document-${last_input_number}-documenttype"])[last()]  ${doc_type}
    centrex.Обрати файл з необхідним типом  ${filepath}  clarifications
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Синхронізуватися із ЦБД
    ...  AND  Page Should Not Contain  Документ завантажується...


Внести зміни в лот
    [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
    ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "lot/update")]
    Wait Until Element Is Visible  id=decision-title
    Run Keyword If  '${fieldname}' == 'title'  Input Text  id=lot-title  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'description'  Input Text  id=lot-description  ${fieldvalue}
    ...  ELSE  Input Text  xpath=//*[@id="${field_name}"]  ${field_value}
    centrex.Обрати файл з необхідним типом  ${file_path}  clarifications
    Scroll To And Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]
    Remove File  ${file_path}


Внести зміни в актив лоту
    [Arguments]  ${username}  ${item_id}  ${tender_uaid}  ${field_name}  ${field_value}
    ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "lot/update")]
    Wait Until Element Is Visible  id=decision-title
    ${quantity}=  Convert To String  ${field_value}
    Run Keyword If   '${field_name}' == 'quantity'  Input Text  xpath=//input[contains(@value, "${item_id}")]/../../following-sibling::div[2]/descendant::input[contains(@name, "quantity")]  ${quantity}
    centrex.Обрати файл з необхідним типом  ${filepath}  clarifications
    Scroll To And Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]
    Remove File  ${file_path}


Внести зміни в умови проведення аукціону
    [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}  ${index}
    ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "lot/update")]
    Wait Until Element Is Visible  id=decision-title
    Run Keyword If  '${fieldname}' == 'value.amount'  Input Amount  name=Lot[auctions][${index}][value][amount]  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'minimalStep.amount'  Input Amount  name=Lot[auctions][${index}][minimalStep][amount]  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'guarantee.amount'  Input Amount  name=Lot[auctions][${index}][guarantee][amount]  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'auctionPeriod.startDate'  Input Date Auction  name=Lot[auctions][${index}][auctionPeriod][startDate]  ${fieldvalue}
    centrex.Обрати файл з необхідним типом  ${filepath}  clarifications
    Scroll To And Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]
    Remove File  ${file_path}


Завантажити документ для видалення лоту
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "lot/update")]
    centrex.Обрати файл з необхідним типом  ${filepath}  clarifications
    centrex.Обрати файл з необхідним типом  ${filepath}  cancellationDetails
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Синхронізуватися із ЦБД
    ...  AND  Page Should Not Contain  Документ завантажується...

Видалити лот
    [Arguments]  ${username}  ${tender_uaid}
    centrex.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  id=delete_btn
    Wait Until Element Is Visible  //button[@data-bb-handler="confirm"]
    Click Element  //button[@data-bb-handler="confirm"]
    Wait Until Element Is Visible  xpath=//div[contains(@class, "alert-success")]


#################################### АУКЦІОНИ ######################################

Пошук тендера по ідентифікатору
    [Arguments]  ${username}  ${tender_uaid}
    Switch Browser  my_alias
    Go To  ${USERS.users['${username}'].homepage}
    Sleep  3
    Закрити Модалку
    Scroll To And Click Element  xpath=//li[@class="dropdown"]/descendant::*[@class="dropdown-toggle"][contains(@href, "tenders")]
    Click Element  xpath=//*[@class="dropdown-menu"]/descendant::*[contains(@href, "/tenders/index")]
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Шукати")]
    Click Element  xpath=//span[@data-target="#additional_filter"]
    Wait Until Element Is Visible  id=tenderssearch-tender_cbd_id
    Wait Until Keyword Succeeds  40 x  5 s  Run Keywords
    ...  Input Text  id=tenderssearch-tender_cbd_id  ${tender_uaid}
    ...  AND  Click Element  xpath=//button[@data-test-id="search"]
    ...  AND  Wait Until Element Is Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  10 x  500 ms  Xpath Should Match X Times  //div[@class="search-result"]  1
    Click Element  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]/../following-sibling::div/a
    Wait Until Page Does Not Contain Element  xpath=//button[contains(text(), "Шукати")]  5
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]
    Синхронізуватися із ЦБД


Оновити сторінку з тендером
    [Arguments]  ${username}  ${tender_uaid}
    centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}


Активувати процедуру
    [Arguments]  ${username}  ${tender_uaid}
    centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
    # Активація процедури на майданчику здійснюється автоматично


Отримати інформацію із тендера
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    Синхронізуватися із ЦБД
    Run Keyword If  'title' in '${field}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
    Run Keyword If  '${field}' == 'status'  Reload Page
    ${value}=  Run Keyword If  'auctionID' in '${field}'  Get Text  xpath=//div[@data-test-id="tenderID"]
    ...  ELSE IF  'awards' in '${field}'  Отримати інформацію із аварду  ${field}
    ...  ELSE IF  'guarantee' in '${field}'  Get Text  xpath=//div[@data-test-id="guarantee"]
    ...  ELSE IF  '${field}' == 'cancellations[0].reason'  Get Text  xpath=//*[@data-test-id="${field.replace('[0]','')}"]
    ...  ELSE IF  '${field}' == 'cancellations[0].status'  Get Element Attribute  xpath=//*[contains(text(), "Причина скасування")]@data-test-id-cancellation-status
    ...  ELSE IF  '${field}' == 'procurementMethodType'  Get Text  xpath=//*[@data-test-id='${field}']
    ...  ELSE  Get Text  xpath=//*[@data-test-id='${field.replace('auction', 'tender')}']
    ${value}=  adapt_data  ${field}  ${value}
    [Return]  ${value}


Отримати інформацію із предмету
    [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field}
    ${value}=  Get Text  xpath=//div[contains(text(),'${item_id}')]/ancestor::div[contains(@class, "item-inf_txt")]/descendant::*[@data-test-id="item.${field}"]
    ${value}=  adapt_data  ${field}  ${value}
    [Return]  ${value}


Отримати інформацію із документа
    [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
    Run Keyword If   '${field}' == 'description'   Fail    ***** Опис документу скасування закупівлі не виводиться на майданчику *****
    ${value}=   Get Text   xpath=//*[contains(text(),'${doc_id}')]
    [Return]  ${value}


Скасувати закупівлю
    [Arguments]  ${username}  ${tender_uaid}  ${cancellation_reason}  ${file_path}  ${cancellation_description}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//*[@data-test-id="sidebar.cancell"]
    Select From List By Value  //*[@id="cancellation-relatedlot"]  tender
    Select From List By Label  //*[@id="cancellation-reason"]  ${cancellation_reason}
    Choose File  xpath=//*[@action="/tender/fileupload"]/input  ${file_path}
    Wait Until Element Is Visible  xpath=(//input[@class="file_name"])[last()]
    Input Text  xpath=(//input[@class="file_name"])[last()]  ${file_path.split('/')[-1]}
    Click Element  xpath=//button[@id="submit-cancel-auction"]
    Wait Until Element Is Visible  xpath=//*[@data-test-id="sidebar.cancell"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Contain Element  xpath=//*[@data-test-id-cancellation-status="active"]


Подати цінову пропозицію
    [Arguments]   ${username}  ${tender_uaid}  ${bid}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Wait Until Element Is Visible  xpath=//input[@id="value-amount"]
    Convert Input Data To String  xpath=//input[@id="value-amount"]  ${bid.data.value.amount}
    Wait Until Keyword Succeeds   5 x   1 s  Run Keywords
    ...  Click Element  xpath=//input[@id="rules_accept"]
    ...  AND  Checkbox Should Be Selected  xpath=//input[@id="rules_accept"]
    Wait Until Keyword Succeeds   5 x   1 s  Run Keywords
    ...  Click Element  xpath=//button[@id="submit_bid"]
    ...  AND  Wait Until Page Contains  очікує модерації
    Перевірити і підтвердити пропозицію  ${username}  ${bid.data.qualified}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Page Should Contain Element  //*[contains(@class, "label-success")][contains(text(), "опубліковано")]


Перевірити і підтвердити пропозицію
    [Arguments]  ${username}  ${status}
    ${url}=  Get Location
    Run Keyword If  ${status}
    ...  Go To  ${host}/bids/send/${url.split('/')[-1]}?token=465
    ...  ELSE  Go To  ${host}/bids/decline/${url.split('/')[-1]}?token=465
    Go To  ${USERS.users['${username}'].homepage}


Змінити цінову пропозицію
    [Arguments]  ${username}  ${tender_uaid}  ${field}  ${value}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Wait Until Element Is Visible  xpath=//button[@id="delete_bid"]
    Click Element  xpath=//button[@id="delete_bid"]
    Reload Page
    Wait Until Element Is Visible  xpath=//input[@id="value-amount"]
    Convert Input Data To String  xpath=//input[@id="value-amount"]  ${value}
    Click Element  xpath=//button[@id="submit_bid"]
    Page Should Contain Element  xpath=//*[contains(@class, "label-success")][contains(text(), "опубліковано")]


Скасувати цінову пропозицію
    [Arguments]  ${username}  ${tender_uaid}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Scroll To And Click Element  //button[@name="delete_bids"]
    Wait Until Element Is Visible  //*[@class="bootbox-body"][contains(text(), "Видалити ставку?")]
    Click Element  xpath=(//button[contains(text(), "Видалити")])[2]
    Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-success')]


Отримати інформацію із пропозиції
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Scroll To  xpath=//input[@id="value-amount"]
    ${value}=  Get Value  xpath=//input[@id="value-amount"]
    ${value}=  adapt_data  ${field}  ${value}
    [Return]  ${value}


Завантажити документ в ставку
    [Arguments]  ${username}  ${file_path}  ${tender_uaid}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    ${value}=  Get Element Attribute  xpath=//input[@id="value-amount"]@value
    centrex.Скасувати цінову пропозицію  ${username}  ${tender_uaid}
    Scroll To  xpath=//*[@action="/tender/fileupload"]/input
    Choose File  xpath=//*[@action="/tender/fileupload"]/input  ${file_path}
    Wait Until Element Is Visible  xpath=(//input[@class="file_name"])[last()]
    Input Text  xpath=(//input[@class="file_name"])[last()]  ${file_path.split('/')[-1]}
    Input Text  xpath=//input[@id="value-amount"]  ${value}
    Select From List By Value  xpath=(//select[@class="select_document_type"])[last()]  commercialProposal
    Wait Until Keyword Succeeds   5 x   1 s  Run Keywords
    ...  Click Element  xpath=//input[@id="rules_accept"]
    ...  AND  Checkbox Should Be Selected  xpath=//input[@id="rules_accept"]
    Wait Until Keyword Succeeds   5 x   1 s  Run Keywords
    ...  Click Element  xpath=//button[@id="submit_bid"]
    ...  AND  Wait Until Page Contains  очікує модерації
    Перевірити і підтвердити пропозицію  ${username}  ${TRUE}


Задати запитання на тендер
    [Arguments]  ${username}  ${tender_uaid}  ${question}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Wait Until Element Is Visible  xpath=//*[@data-test-id="sidebar.questions"]
    Click Element  xpath=//*[@data-test-id="sidebar.questions"]
    Input Text  xpath=//input[@id="question-title"]  ${question.data.title}
    Input Text  xpath=//textarea[@id="question-description"]  ${question.data.description}
    Select From List By Value  //select[@id="question-questionof"]  tender
    Click Element  //button[@name="question_submit"]
    Wait Until Page Contains  ${question.data.title}


Задати запитання на предмет
    [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Wait Until Element Is Visible  xpath=//*[@data-test-id="sidebar.questions"]
    Click Element  xpath=//*[@data-test-id="sidebar.questions"]
    Input Text  xpath=//input[@id="question-title"]  ${question.data.title}
    Input Text  xpath=//textarea[@id="question-description"]  ${question.data.description}
    ${item_name}=  Get Text  xpath=//*[@id="question-questionof"]/descendant::*[contains(text(), "${item_id}")]
    Select From List By Label  xpath=//select[@id="question-questionof"]  ${item_name}
    Click Element  //button[@name="question_submit"]
    Wait Until Page Contains  ${question.data.title}


Відповісти на запитання
    [Arguments]  ${tender_owner}  ${tender_uaid}  ${answer}  ${question_id}
    Run Keyword And Ignore Error  Click Element  xpath=//*[@data-test-id="sidebar.questions"]
    Click Element  xpath=//*[@id="slidePanelToggle"]
    Input Text  //*[@data-test-id="question.title"][contains(text(), "${question_id}")]/following-sibling::form[contains(@action, "tender/questions")]/descendant::textarea  ${answer.data.answer}
    Scroll To And Click Element  xpath=//*[@data-test-id="question.title"][contains(text(), "${question_id}")]/../descendant::button[@name="answer_question_submit"]


Отримати інформацію із запитання
    [Arguments]  ${username}  ${tender_uaid}  ${object_id}  ${field}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//*[@data-test-id="sidebar.questions"]
    Wait Until Element Is Not Visible  xpath=//*[@data-test-id="sidebar.questions"]
    ${value}=  Get Text  //*[contains(text(), '${object_id}')]/../descendant::*[@data-test-id='question.${field}']
    [Return]  ${value}


Отримати посилання на аукціон для учасника
    [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=${Empty}
    Switch Browser  my_alias
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Wait Until Element Is Visible  //a[@class="auction_seller_url"]
    ${current_url}=  Get Location
    Execute Javascript  window['url'] = null; $.get( "${USERS.users['${username}'].homepage}/seller/tender/updatebid", { id: "${current_url.split("/")[-1]}"}, function(data){ window['url'] = data.data.participationUrl },'json');
    Wait Until Keyword Succeeds  20 x  1 s  JQuery Ajax Should Complete
    ${link}=  Execute Javascript  return window['url'];
    [Return]  ${link}


Отримати посилання на аукціон для глядача
    [Arguments]  ${viewer}  ${tender_uaid}  ${lot_id}=${Empty}
    centrex.Пошук Тендера По Ідентифікатору  ${viewer}  ${tender_uaid}
    ${link}=  Get Element Attribute  xpath=//*[contains(text(), "Посилання")]/../descendant::*[@class="h4"]/a@href
    [Return]  ${link}


#################################### AWARDING + CONTRACTING ######################################

Отримати інформацію із аварду
    [Arguments]  ${field}
    ${index}=  Set Variable  ${field.split('[')[1].split(']')[0]}
    ${index}=  Convert To Integer  ${index}
    Перейти на сторінку кваліфікації
    Reload Page
    ${value}=  Get Element Attribute  xpath=(//div[@data-mtitle="Статус:"]/input)[${index + 1}]@award_status
    [Return]  ${value}


Отримати кількість авардів в тендері
    [Arguments]  ${username}  ${tender_uaid}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Перейти на сторінку кваліфікації
    ${awards}=  Get Matching Xpath Count  xpath=//div[contains(@class, "qtable")]/descendant::div[@data-mtitle="№"]
    ${n_awards}=  Convert To Integer  ${awards}
    [Return]  ${n_awards}


Завантажити протокол погодження в авард
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${award_index}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Перейти на сторінку кваліфікації
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Опублікувати рішення про викуп")]
    Click Element  xpath=//button[contains(text(), "Опублікувати рішення про викуп")]
    Wait Until Element Is Visible  xpath=//div[contains(text(), "Опублікувати рішення про викуп")]
    Choose File  xpath=//div[@id="admission-form-upload-file"]/descendant::input[@name="FileUpload[file][]"]  ${file_path}
    Wait Until Element Is Visible  xpath=//button[contains(@class, "delete-file-verification")]


Активувати кваліфікацію учасника
    [Arguments]  ${username}  ${tender_uaid}
    Click Element  xpath=//button[@name="admission"]
    Wait Until Element Is Not Visible  xpath=//button[@name="admission"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Not Contain Element  xpath=//button[@onclick="window.location.reload();"]


Завантажити протокол аукціону в авард
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${award_index}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Перейти на сторінку кваліфікації
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Завантаження протоколу")]
    Click Element  xpath=//button[contains(text(), "Завантаження протоколу")]
    Wait Until Element Is Visible  xpath=//div[contains(text(), "Завантаження протоколу")]
    Choose File  xpath=//div[@id="verification-form-upload-file"]/descendant::input[@name="FileUpload[file][]"]  ${file_path}
    Wait Until Element Is Visible  xpath=//button[contains(@class, "delete-file-verification")]
    Click Element  xpath=//button[@name="protocol_upload"]
    Wait Until Element Is Not Visible  xpath=//button[@name="protocol_upload"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Not Contain Element  xpath=//button[@onclick="window.location.reload();"]


Підтвердити постачальника
    [Arguments]  ${username}  ${tender_uaid}  ${number}
    Log  Необхідні дії було виконано у "Завантажити протокол аукціону в авард"


Завантажити протокол дискваліфікації в авард
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${award_index}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Перейти на сторінку кваліфікації
    Wait Until Element Is Visible  xpath=//button[@data-toggle="modal"][contains(text(), "Дисквалiфiкувати")]
    Click Element  xpath=//button[@data-toggle="modal"][contains(text(), "Дисквалiфiкувати")]
    Wait Until Element Is Visible  xpath=//div[contains(@class, "h2")][contains(text(), "Дискваліфікація")]
    Wait Until Element Is Visible  xpath=(//*[@name="Award[cause][]"])[1]/..
    Click Element  xpath=(//*[@name="Award[cause][]"])[1]/..
    Choose File  xpath=//div[@id="disqualification-form-upload-file"]/descendant::input[@name="FileUpload[file][]"]  ${file_path}
    Wait Until Element Is Visible  xpath=//button[contains(@class, "delete-file-verification")]


Дискваліфікувати постачальника
    [Arguments]  ${username}  ${tender_uaid}  ${number}  ${description}
    Input Text  //textarea[@id="award-description"]  ${description}
    Click Element  xpath=//button[@id="disqualification"]
    Wait Until Element Is Not Visible  xpath=//button[@id="disqualification"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Not Contain Element  xpath=//button[@onclick="window.location.reload();"]


Скасування рішення кваліфікаційної комісії
    [Arguments]  ${username}  ${tender_uaid}  ${number}
    ${award_status}=  Set Variable If  '${ROLE}' == 'tender_owner'  Рiшення скасовано  Відмова від очікування
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Перейти на сторінку кваліфікації
    Wait Until Element Is Visible  //button[contains(text(), "Забрати гарантійний внесок")]
    Click Element  //button[contains(text(), "Забрати гарантійний внесок")]
    Wait Until Element Is Visible  //div[contains(text(), "Подальшу участь буде скасовано")]
    Click Element  //*[@class="modal-footer"]/button[contains(text(), "Застосувати")]
    Wait Until Element Is Not Visible  //*[@class="modal-footer"]/button[contains(text(), "Застосувати")]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Contains  ${award_status}


Завантажити протокол скасування в контракт
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${award_index}
    centrex.Завантажити протокол дискваліфікації в авард  ${username}  ${tender_uaid}  ${file_path}  ${award_index}


Скасувати контракт
    [Arguments]  ${username}  ${tender_uaid}  ${number}
    Click Element  xpath=//button[@id="disqualification"]
    Wait Until Element Is Not Visible  xpath=//button[@id="disqualification"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Not Contain Element  xpath=//button[@onclick="window.location.reload();"]


Встановити дату підписання угоди
    [Arguments]  ${username}  ${tender_uaid}  ${index}  ${date}
    ${date}=  Convert Date  ${date.split(".")[0]}  date_format=%Y-%m-%dT%H:%M:%S  result_format=%d/%m/%Y %H:%M:%S
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Перейти на сторінку кваліфікації
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Договір")]
    Click Element  xpath=//button[contains(text(), "Договір")]
    Wait Element Animation  name=Contract[dateSigned]
    Clear Element Text  name=Contract[dateSigned]
    Execute Javascript  document.querySelector('[name="Contract[dateSigned]"]').value = "${date}"
    Click Element  xpath=//button[@id="contract-fill-data"]
    Wait Until Element Is Not Visible  xpath=//button[@id="contract-fill-data"]


Завантажити угоду до тендера
    [Arguments]  ${username}  ${tender_uaid}  ${number}  ${file_path}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Перейти на сторінку кваліфікації
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Договір")]
    Click Element  xpath=//button[contains(text(), "Договір")]
    Wait Element Animation  xpath=//div[@id="uploadcontract"]/descendant::input
    Choose File  xpath=//div[@id="uploadcontract"]/descendant::input  ${file_path}
    Wait Until Element Is Visible  xpath=(//select[contains(@class,"contract_document_type_select")])[last()]
    Select From List By Value  xpath=(//select[contains(@class,"contract_document_type_select")])[last()]  contractSigned
    Input Text  xpath=//input[@id="contract-contractnumber"]  1234567890
    Click Element  xpath=//button[@id="contract-fill-data"]
    Wait Until Element Is Not Visible  xpath=//button[@id="contract-fill-data"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Contain Element  xpath=//input[@id="contract-activate"]


Підтвердити підписання контракту
    [Arguments]  ${username}  ${tender_uaid}  ${number}
    centrex.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Перейти на сторінку кваліфікації
    Click Element  xpath=//input[@id="contract-activate"]
    Wait Until Element Is Visible  xpath=//h4[contains(text(), "Активація контракту")]
    Click Element  xpath=//button[@data-bb-handler="confirm"]
    Wait Until Keyword Succeeds  10 x  5 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Contain Element  xpath=//div[@data-test-id="status"][contains(text(), "Аукціон завершено. Договір підписано")]


Перейти на сторінку кваліфікації
    ${status_q}=  Run Keyword And Return Status  Page Should Contain Element  xpath=//a[contains(text(), "Таблиця квалiфiкацiї")]  3
    ${status_p}=  Run Keyword And Return Status  Page Should Contain Element  xpath=//a[contains(text(), "Протокол розкриття пропозицiй")]  2
    Run Keyword If  ${status_q}  Click Element  xpath=//a[contains(text(), "Таблиця квалiфiкацiї")]
    ...  ELSE IF  ${status_p}  Click Element  xpath=//a[contains(text(), "Протокол розкриття пропозицiй")]
    Закрити Модалку
    Wait Until Element Is Visible  xpath=//h1[contains(text(), "Квалiфiкацiя учасникiв")]


Отримати інформацію з активу в договорі
    [Arguments]  ${username}  ${contract_uaid}  ${item_id}  ${field_name}
    centrex.Пошук договору по ідентифікатору  ${username}  ${contract_uaid}
    ${value}=  centrex.Отримати інформацію із предмету  ${username}  ${contract_uaid}  ${item_id}  ${field_name}
    [Return]  ${value}


Пошук договору по ідентифікатору
    [Arguments]  ${username}  ${contract_uaid}
    Switch Browser  my_alias
    Go To  ${USERS.users['${username}'].homepage}
    Wait Until Element Is Visible  xpath=//a[@class="dropdown-toggle"][contains(text(),"м.Приватизація")]
    Click Element  xpath=//a[@class="dropdown-toggle"][contains(text(),"м.Приватизація")]
    Wait Until Element Is Visible  xpath=//*[@id="h-menu"]/descendant::a[contains(@href, "contracting")]
    Click Element  xpath=//*[@id="h-menu"]/descendant::a[contains(@href, "contracting")]
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Шукати")]
    Wait Until Keyword Succeeds  40 x  5 s  Run Keywords
    ...  Input Text  id=contractingsearch-contract_cbd_id  ${contract_uaid}
    ...  AND  Click Element  xpath=//button[contains(text(), "Шукати")]
    ...  AND  Wait Until Element Is Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${contract_uaid}")]
    Wait Until Keyword Succeeds  10 x  500 ms  Xpath Should Match X Times  //div[@class="search-result_article"]  1
    Click Element  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${contract_uaid}")]/../../div[2]/a[contains(@href, "/contracting/view")]
    Wait Until Page Does Not Contain Element  xpath=//button[contains(text(), "Шукати")]  10
    Wait Until Element Is Visible  xpath=//div[@data-test-id="contractID"]
    Синхронізуватися із ЦБД


Отримати інформацію із договору
    [Arguments]  ${username}  ${contract_uaid}  ${field}
    centrex.Пошук договору по ідентифікатору  ${username}  ${contract_uaid}
    Синхронізуватися із ЦБД
    ${value}=  Get Text  xpath=//div[@data-test-id="${field}"]
    ${value}=  adapted_dictionary  ${value}
    [Return]  ${value}


Активувати контракт
    [Arguments]  ${username}  ${contract_uaid}
    Wait Until Keyword Succeeds  20 x  6 s  Run Keywords
    ...  centrex.Пошук договору по ідентифікатору  ${username}  ${contract_uaid}
    ...  AND  Page Should Contain Element  xpath=//div[@data-test-id="status" and contains(text(), "Очікується оплата ")]


Вказати дату отримання оплати
    [Arguments]  ${username}  ${contract_uaid}  ${dateMet}  ${index}
    centrex.Пошук договору по ідентифікатору  ${username}  ${contract_uaid}
    Click Element  xpath=//button[@class="mk-btn mk-btn_default"][contains(text(), "Оплата договору")]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Element Is Visible  xpath=//div[@class="h2 text-center"][contains(text(), "Оплата договору")]
    Click Element  xpath=//select[@id="milestone-status"]
    ${date_paid}=  Convert Date  ${dateMet.split("+")[0]}  date_format=%Y-%m-%dT%H:%M:%S  result_format=%d.%m.%Y %H:%M
    Wait Element Animation  xpath=//input[@name="Milestone[dateMet]"]
    Focus  xpath=//input[@name="Milestone[dateMet]"]
    Clear Element Text	xpath=//input[@name="Milestone[dateMet]"]
    Execute Javascript  $("[name='Milestone[dateMet]']")[0].value = "${date_paid}"
    Sleep  3
    Click Element  xpath=//button[@class="mk-btn mk-btn_accept"][contains(text(),"Завантажити дані")]
    Wait Until Element Is Not Visible  xpath=//*[contains(@class, "modal-backdrop")]


Підтвердити відсутність оплати
    [Arguments]  ${username}  ${contract_uaid}  ${index}
    centrex.Пошук договору по ідентифікатору  ${username}  ${contract_uaid}
    Click Element  xpath=//button[@class="mk-btn mk-btn_default"][contains(text(), "Оплата договору")]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Element Is Visible  xpath=//div[@class="h2 text-center"][contains(text(), "Оплата договору")]
    Select From List By Value  xpath=//select[@id="milestone-status"]  notMet
    Click Element  xpath=//button[@class="mk-btn mk-btn_accept"][contains(text(),"Завантажити дані")]
    Wait Until Element Is Not Visible  xpath=//*[contains(@class, "modal-backdrop")]


Завантажити наказ про завершення приватизації
    [Arguments]  ${username}  ${contract_uaid}  ${file_path}
    centrex.Пошук договору по ідентифікатору  ${username}  ${contract_uaid}
    Click Element  xpath=//button[contains(text(), 'Наказ про завершення')]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Element Is Visible  xpath=//button[contains(text(), 'Завантажити дані')]
    Click Element  xpath=//div[contains(text(), 'Додати документ')]
    Choose File  xpath=//input[contains(@id,"ajax-upload-id")]  ${file_path}
    Wait Until Element Is Visible  xpath=//select[@id="document-0-documenttype"]
    Select From List By Value  xpath=//select[@id="document-0-documenttype"]  approvalProtocol


Вказати дату прийняття наказу
    [Arguments]  ${username}  ${contract_uaid}  ${dateMet}
    centrex.Пошук договору по ідентифікатору  ${username}  ${contract_uaid}
    ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
    Click Element  xpath=//button[contains(text(), 'Наказ про завершення приватизації')]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Element Is Visible  xpath=//button[contains(text(), 'Завантажити дані')]
    Click Element  xpath=//div[contains(text(), 'Додати документ')]
    Choose File  xpath=//input[contains(@id,"ajax-upload-id")]  ${file_path}
    Wait Until Page Contains Element  //select[@id='document-0-documenttype'] /option[contains(text(), 'Наказ про приватизацію')]
    Select From List By Value  xpath=//select[@id="document-0-documenttype"]  approvalProtocol
    ${date_nakaz}=  Convert Date  ${dateMet.split("+")[0]}   date_format=%Y-%m-%dT%H:%M:%S  result_format=%d.%m.%Y %H:%M
    Execute Javascript  $("[name='Milestone[dateMet]']")[0].value = "${date_nakaz}"
    Click Element  xpath=//button[@class="mk-btn mk-btn_accept"]
    Wait Until Element Is Not Visible  xpath=//*[contains(@class, "modal-backdrop")]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10
    Remove File  ${file_path}


Підтвердити відсутність наказу про приватизацію
    [Arguments]  ${username}  ${contract_uaid}  ${file_path}
    centrex.Пошук договору по ідентифікатору  ${username}  ${contract_uaid}
    Click Element  xpath=//button[contains(text(), 'Наказ про завершення приватизації')]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Element Is Visible  xpath=//button[contains(text(), 'Завантажити дані')]
    Click Element  xpath=//div[contains(text(), 'Додати документ')]
    Choose File  xpath=//input[contains(@id,"ajax-upload-id")]  ${file_path}
    Wait Until Element Is Visible  xpath=//select[@class="document-type"][@id="document-0-documenttype"]
    Select From List By Value  xpath=//select[@id="document-0-documenttype"]  rejectionProtocol
    Select From List By Value  xpath=//select[@id="milestone-status"]  notMet
    Click Element  xpath=//button[@class="mk-btn mk-btn_accept"]
    Wait Until Element Is Not Visible  xpath=//*[contains(@class, "modal-backdrop")]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10


Вказати дату виконання умов контракту
    [Arguments]  ${username}  ${contract_uaid}  ${dateMet}
    centrex.Пошук договору по ідентифікатору  ${username}  ${contract_uaid}
    ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
    Click Element  xpath=//button[contains(text(), 'Виконання умов продажу')]
    Wait Until Element Is Visible  xpath=//div[contains(text(), 'Додати документ')]
    Click Element  xpath=//div[contains(text(), 'Додати документ')]
    Choose File  xpath=//input[contains(@id,"ajax-upload-id")]  ${file_path}
    Wait Until Page Contains Element  //select[@id="document-0-documenttype"] /option[contains(text(),"Документи, що підтверджують виконання умов продажу")]
    Select From List By Value  xpath=//select[@id="document-0-documenttype"]  contractNotice
    ${date_paid}=  Convert Date  ${dateMet.split("+")[0]}   date_format=%Y-%m-%dT%H:%M:%S  result_format=%d.%m.%Y %H:%M
    Execute Javascript  $("[name='Milestone[dateMet]']")[0].value = "${date_paid}"
    Click Element  xpath=//button[@class="mk-btn mk-btn_accept"][contains(text(),"Завантажити дані")]
    Wait Until Element Is Not Visible  xpath=//*[contains(@class, "modal-backdrop")]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10
    Remove File  ${file_path}


Підтвердити невиконання умов приватизації
    [Arguments]  ${username}  ${contract_uaid}
    centrex.Пошук договору по ідентифікатору  ${username}  ${contract_uaid}
    ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
    Click Element  xpath=//button[contains(text(), 'Виконання умов продажу')]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Element Is Visible  xpath=//button[contains(text(), 'Завантажити дані')]
    Click Element  xpath=//div[contains(text(), 'Додати документ')]
    Choose File  xpath=//input[contains(@id,"ajax-upload-id")]  ${file_path}
    Wait Until Element Is Visible  xpath=//select[@class="document-type"][@id="document-0-documenttype"]
    Select From List By Value  xpath=//select[@id="document-0-documenttype"]  rejectionProtocol
    Select From List By Value  xpath=//select[@id="milestone-status"]  notMet
    Click Element  xpath=//button[@class="mk-btn mk-btn_accept"]
    Wait Until Element Is Not Visible  xpath=//*[contains(@class, "modal-backdrop")]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10
    Remove File  ${file_path}



##################################################################################
Input Amount
    [Arguments]  ${locator}  ${value}
    ${value}=  Convert To String  ${value}
    Clear Element Text  ${locator}
    Input Text  ${locator}  ${value}


Input Date Auction
    [Arguments]  ${locator}  ${value}
    ${date}=  Convert Date  ${value.split(".")[0]}  date_format=%Y-%m-%dT%H:%M:%S  result_format=%d.%m.%Y %H:%M
    Clear Element Text  ${locator}
    Execute Javascript  document.querySelector('[${locator.split("=")[0]}="${locator.split("=")[1]}"]').value = "${date}"


Отримати документ
    [Arguments]  ${username}  ${TENDER['TENDER_UAID']}  ${doc_id}
    Run keyword if  "Відображення вмісту документації до об'єкта МП" == "${TEST NAME}"  Wait until keyword succeeds  40 x  10 s  Run Keywords
        ...  Reload Page
        ...  AND  Page Should Contain element  xpath=//a[contains(text(), '${doc_id}')]
    ${file_name}=  Get Text  xpath=//a[contains(text(), '${doc_id}')]
    ${url}=  Get Element Attribute  xpath=//a[contains(text(), '${doc_id}')]@href
    download_file  ${url}  ${file_name}  ${OUTPUT_DIR}
    [Return]  ${file_name}


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


Convert Input Data To String
    [Arguments]  ${locator}  ${value}
    ${value}=  Convert To String  ${value}
    Input Text  ${locator}  ${value}


JQuery Ajax Should Complete
    ${active}=  Execute Javascript  return jQuery.active
    Should Be Equal  "${active}"  "0"


Wait Element Animation
    [Arguments]  ${locator}
    Set Test Variable  ${prev_vert_pos}  0
    Wait Until Keyword Succeeds  20 x  500 ms  Position Should Equals  ${locator}


Position Should Equals
    [Arguments]  ${locator}
    ${current_vert_pos}=  Get Vertical Position  ${locator}
    ${status}=  Run Keyword And Return Status  Should Be Equal  ${prev_vert_pos}  ${current_vert_pos}
    Set Test Variable  ${prev_vert_pos}  ${current_vert_pos}
    Should Be True  ${status}
