*** Settings ***
Library  Selenium2Library
Library  BuiltIn
Library  Collections
Library  String
Library  DateTime
Library  centrex_service.py

*** Variables ***

*** Keywords ***

Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  ${tender_data}=   adapt_procuringEntity   ${role_name}   ${tender_data}
  [return]  ${tender_data}

Підготувати клієнт для користувача
  [Arguments]  ${username}
  Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=${username}
  Set Window Size  @{USERS.users['${username}'].size}
  Set Window Position  @{USERS.users['${username}'].position}
  Run Keyword If  '${username}' != 'centrex_Viewer'  Run Keywords
  ...  Login  ${username}
  ...  AND  Run Keyword And Ignore Error  Wait Until Keyword Succeeds  10 x  1 s  Закрити модалку з новинами

Закрити модалку з новинами
  Wait Until Element Is Enabled   xpath=//button[@data-dismiss="modal"]
  Click Element   xpath=//button[@data-dismiss="modal"]
  Wait Until Element Is Not Visible  xpath=//button[@data-dismiss="modal"]

Login
  [Arguments]  ${username}
  Wait Until Page Contains Element  id=loginform-username  10
  Input text  id=loginform-username  ${USERS.users['${username}'].login}
  Input text  id=loginform-password  ${USERS.users['${username}'].password}
  Click Element  name=login-button

###############################################################################################################
######################################    СТВОРЕННЯ ТЕНДЕРУ    ################################################
###############################################################################################################

Створити тендер
  [Arguments]  ${username}  ${tender_data}
  ${items}=  Get From Dictionary  ${tender_data.data}  items
  ${number_of_items}=  Get Length  ${items}
  ${tenderAttempts}=   Convert To String   ${tender_data.data.tenderAttempts}
  Switch Browser  ${username}
  Wait Until Page Contains Element  xpath=//a[@href="http://eauction.centrex.com.ua/tenders"]  10
  Click Element  xpath=//a[@href="http://eauction.centrex.com.ua/tenders"]
  Click Element  xpath=//a[@href="http://eauction.centrex.com.ua/tenders/index"]
  Click Element  xpath=//a[contains(@href,"http://eauction.centrex.com.ua/buyer/tender/create")]
  Select From List By Value  name=tender_method  open_${tender_data.data.procurementMethodType}
  Conv And Select From List By Value  name=Tender[value][valueAddedTaxIncluded]  ${tender_data.data.value.valueAddedTaxIncluded}
  ConvToStr And Input Text  name=Tender[value][amount]  ${tender_data.data.value.amount}
  ConvToStr And Input Text  name=Tender[minimalStep][amount]  ${tender_data.data.minimalStep.amount}
  ConvToStr And Input Text  name=Tender[guarantee][amount]  ${tender_data.data.guarantee.amount}
  Input text  name=Tender[title]  ${tender_data.data.title}
  Input text  name=Tender[dgfID]  ${tender_data.data.dgfID}
  Input text  name=Tender[description]  ${tender_data.data.description}
  Input text  name=Tender[dgfDecisionID]  ${tender_data.data.dgfDecisionID}
  Select From List By Value  name=Tender[tenderAttempts]  ${tenderAttempts}
  Input Date  name=Tender[dgfDecisionDate]  ${tender_data.data.dgfDecisionDate}
  Input Date  name=Tender[auctionPeriod][startDate]  ${tender_data.data.auctionPeriod.startDate}
  :FOR  ${index}  IN RANGE  ${number_of_items}
  \  Run Keyword If  ${index} != 0  Click Element  xpath=(//button[contains(@class,'add_item')])[last()]
  \  Додати предмет  ${items[${index}]}  ${index}
  Click Element  xpath= //button[@class="btn btn-default btn_submit_form"]
  Wait Until Page Contains Element  xpath=//b[@tid="tenderID"]  10
  ${tender_uaid}=  Get Text  xpath=//b[@tid="tenderID"]
  [return]  ${tender_uaid}

Додати предмет
  [Arguments]  ${item}  ${index}
  ${index}=  Convert To Integer  ${index}
  Input text  name=Tender[items][${index}][description]  ${item.description}
  Input text  name=Tender[items][${index}][quantity]  ${item.quantity}
  Select From List By Value  name=Tender[items][${index}][unit][code]  ${item.unit.code}
  Click Element  name=Tender[items][${index}][classification][description]
  Wait Until Element Is Visible  id=search_code   30
  Input text  id=search_code  ${item.classification.id}
  Wait Until Page Contains  ${item.classification.id}
  Click Element  xpath=//span[contains(text(),'${item.classification.id}')]
  Click Element  id=btn-ok
  Run Keyword And Ignore Error  Wait Until Element Is Not Visible  xpath=//div[@class="modal-backdrop fade"]  10
  Input text  name=Tender[items][${index}][address][countryName]  ${item.deliveryAddress.countryName}
  Input text  name=Tender[items][${index}][address][region]  ${item.deliveryAddress.region}
  Input text  name=Tender[items][${index}][address][locality]  ${item.deliveryAddress.locality}
  Input text  name=Tender[items][${index}][address][streetAddress]  ${item.deliveryAddress.streetAddress}
  Input text  name=Tender[items][${index}][address][postalCode]  ${item.deliveryAddress.postalCode}
  Select From List By Value  name=Tender[procuringEntity][contactPoint][fio]  1

Додати предмет закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${item}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Run Keyword And Ignore Error  Click Element  xpath=(//button[contains(@class,'add_item')])[last()]

Видалити предмет закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Run Keyword And Ignore Error  Click Element  xpath=(//button[contains(@class,'delete_item')])[last()]

Завантажити документ
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}  ${illustration}=False
  Switch Browser  ${username}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Wait Until Element Is Visible  xpath=(//input[@name="FileUpload[file]"]/ancestor::a[contains(@class,'uploadfile')])[last()]
  Choose File  xpath=(//*[@name="FileUpload[file]"])[last()]  ${filepath}
  Select From List By Value   xpath=//label[text()='${filepath.split('/')[-1]}']/../../descendant::*[contains(@name,"[documentType]")]   illustration
  Input Text  xpath=//label[text()='${filepath.split('/')[-1]}']/../../descendant::input[contains(@name,'[title]')]   ${filepath.split('/')[-1]}
  Click Button  xpath=//button[@class="btn btn-default btn_submit_form"]
  Wait Until Element Is Not Visible   xpath=//button[@class="btn btn-default btn_submit_form"]
  Дочекатися завантаження документу

Завантажити ілюстрацію
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  centrex.Завантажити документ   ${username}  ${filepath}  ${tender_uaid}  True

Дочекатися завантаження документу
  Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
  ...  Reload Page
  ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10

Додати Virtual Data Room
  [Arguments]  ${username}  ${tender_uaid}  ${vdr_url}  ${title}=Sample Virtual Data Room
  centrex.Пошук тендера по ідентифікатору   ${username}   ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Wait Until Element Is Visible  xpath=//a[contains(@class,'virtualDataRoom')]
  Click Element  xpath=//a[contains(@class,'virtualDataRoom')]
  Wait Until Element Is Visible  xpath=(//input[contains(@name,'[url]')])[last()]
  Input Text  xpath=(//input[contains(@name,'[url]')])[last()]  ${vdr_url}
  Click Button  xpath=//button[@class="btn btn-default btn_submit_form"]

Завантажити документ в тендер з типом
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${documentType}
  Switch Browser  ${username}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Choose File  xpath=(//*[@name="FileUpload[file]"])[last()]  ${filepath}
  Select From List By Value   xpath=//label[text()='${filepath.split('/')[-1]}']/../../descendant::*[contains(@name,"[documentType]")]   ${documentType}
  Input Text  xpath=//label[text()='${filepath.split('/')[-1]}']/../../descendant::input[contains(@name,'[title]')]   ${filepath.split('/')[-1]}
  Click Button  xpath=//button[@class="btn btn-default btn_submit_form"]
  Wait Until Keyword Succeeds  20 x  1 s  Element Should Not Be Visible  xpath=//button[@class="btn btn-default btn_submit_form"]
  Дочекатися завантаження документу

Додати публічний паспорт активу
  [Arguments]  ${username}  ${tender_uaid}  ${certificate_url}  ${title}=Public Asset Certificate
  centrex.Пошук тендера по ідентифікатору   ${username}   ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Click Element  id=addPublicCertificate
  Wait Until Element Is Visible  xpath=(//div[contains(@class, 'certificate_block')]/descendant::input[contains(@name,'[url]')])[last()]
  Input Text  xpath=(//div[contains(@class,'certificate_block')]/descendant::input[contains(@name,'[url]')])[last()]  ${certificate_url}

Додати офлайн документ
  [Arguments]  ${username}  ${tender_uaid}  ${accessDetails}  ${title}=Familiarization with bank asset
  centrex.Пошук тендера по ідентифікатору   ${username}   ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Click Element  id=addDocWtDoc
  Wait Until Element Is Visible  xpath=(//div[contains(@class, 'docwdoc_block')]/descendant::textarea[contains(@name,'[accessDetails]')])[last()]
  Input Text  xpath=(//div[contains(@class,'docwdoc_block')]/descendant::textarea[contains(@name,'[accessDetails]')])[last()]  ${accessDetails}

Пошук тендера по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  Switch browser  ${username}
  Go To  http://eauction.centrex.com.ua
  Click Element  xpath=//a[@href="http://eauction.centrex.com.ua/tenders"]
  Click Element  xpath=//a[@href="http://eauction.centrex.com.ua/tenders/index"]
  Wait Until Element Is Visible  id=more-filter
  Wait Until Keyword Succeeds  10 x  0.4 s  Run Keywords
  ...  Click Element  id=more-filter
  ...  AND  Wait Until Element Is Visible  name=TendersSearch[tender_cbd_id]
  Input text  name=TendersSearch[tender_cbd_id]  ${tender_uaid}
  Click Element  xpath=//button[@tid="search"]
  Wait Until Keyword Succeeds  30x  400ms  Перейти на сторінку з інформацією про тендер  ${tender_uaid}

Перейти на сторінку з інформацією про тендер
  [Arguments]  ${tender_uaid}
  Click Element  xpath=//h3[contains(text(),'${tender_uaid}') and contains('${tender_uaid}',text())]/ancestor::div[@class="row"]/descendant::a[contains(@href,'/tender/view/')]
  Wait Until Element Is Visible  xpath=//*[@tid="tenderID"]

Оновити сторінку з тендером
  [Arguments]  ${username}  ${tender_uaid}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}

Внести зміни в тендер
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}  ${field_value}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Input text  name=Tender[${field_name}]  ${field_value}
  Click Element  xpath=//button[@class="btn btn-default btn_submit_form"]
  Wait Until Page Contains  ${field_value}  30

###############################################################################################################
##########################################    СКАСУВАННЯ    ###################################################
###############################################################################################################

Скасувати закупівлю
  [Arguments]  ${username}  ${tender_uaid}  ${cancellation_reason}  ${document}  ${new_description}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href,'/tender/cancel/')]
  Select From List By Value  id=cancellation-relatedlot  tender
  Select From List By Value  id=cancellation-reason  ${cancellation_reason}
  Choose File  name=FileUpload[file]  ${document}
  Wait Until Element Is Visible  name=Tender[cancellations][documents][0][title]
  Input Text  name=Tender[cancellations][documents][0][title]  ${document.replace('/tmp/', '')}
  Click Element  xpath=//button[@type="submit"]
  Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-success')]
  Wait Until Keyword Succeeds  30 x  1 m  Звірити статус тендера  ${username}  ${tender_uaid}  cancelled

###############################################################################################################
############################################    ПИТАННЯ    ####################################################
###############################################################################################################

Задати питання
  [Arguments]  ${username}  ${tender_uaid}  ${question}  ${item_id}=False
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Element Is Enabled  xpath=//a[@tid="sidebar.questions"]
  Click Element  xpath=//a[@tid="sidebar.questions"]
  ${status}  ${item_option}=   Run Keyword And Ignore Error   Get Text   //option[contains(text(), '${item_id}')]
  Run Keyword If  '${status}' == 'PASS'   Select From List By Label  name=Question[questionOf]  ${item_option}
  Input Text  name=Question[title]  ${question.data.title}
  Input Text  name=Question[description]  ${question.data.description}
  Click Element  name=question_submit
  Wait Until Page Contains Element  xpath=//div[contains(@class,'alert-success')]  30

Задати запитання на тендер
  [Arguments]  ${username}  ${tender_uaid}  ${question}
  centrex.Задати питання  ${username}  ${tender_uaid}  ${question}

Задати запитання на предмет
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question}
  centrex.Задати питання  ${username}  ${tender_uaid}  ${question}  ${item_id}

Відповісти на запитання
  [Arguments]  ${username}  ${tender_uaid}  ${answer_data}  ${question_id}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Element Is Enabled  xpath=//a[@tid="sidebar.questions"]
  Click Element  xpath=//a[@tid="sidebar.questions"]
  Wait Until Element Is Visible  xpath=//h4[contains(text(),'${question_id}')]/../descendant::textarea[contains(@name,'[answer]')]
  Input text  xpath=//h4[contains(text(),'${question_id}')]/../descendant::textarea[contains(@name,'[answer]')]  ${answer_data.data.answer}
  Click Element  xpath=//h4[contains(text(),'${question_id}')]/following-sibling::button[@name="answer_question_submit"]
  Wait Until Page Contains Element  xpath=//div[contains(@class,'alert-success')]  30

###############################################################################################################
###################################    ВІДОБРАЖЕННЯ ІНФОРМАЦІЇ    #############################################
###############################################################################################################

Отримати інформацію із тендера
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  ${value}=  Run Keyword If
  ...  'status' in '${field_name}'  Отримати інформацію про статус  ${field_name}
  ...  ELSE IF  'value' in '${field_name}'  Get Text  xpath=//*[@tid="value.amount"]
  ...  ELSE IF  '${field_name}' == 'auctionPeriod.startDate'  Get Text  xpath=(//*[@tid="tenderPeriod.endDate"])[2]
  ...  ELSE IF  '${field_name}' == 'dgfDecisionDate'  Get Element Attribute  xpath=//*[@tid="dgfDecisionDate"]@data-ddate
  ...  ELSE IF  '${field_name}' == 'tenderAttempts'  Get Element Attribute  xpath=//*[@tid="tenderAttempts"]@at_count
  ...  ELSE IF  'cancellations' in '${field_name}'  Get Text  xpath=//*[@tid="${field_name.replace('[0]','')}"]
  ...  ELSE  Get Text  xpath=//*[@tid="${field_name.replace('auction', 'tender')}"]
  ${value}=  adapt_view_data  ${value}  ${field_name}
  [return]  ${value}

Отримати інформацію про статус
  [Arguments]  ${field_name}
  Click Element   xpath=//a[text()='Інформація про аукціон']
  ${value}=  Run Keyword If  'cancellations' in '${field_name}'
  ...  Get Text  xpath=//div[contains(@class,'alert-danger')]/h3[1]
  ...  ELSE  Get Text  xpath=//h2[@tid="${field_name.split('.')[-1]}"]
  [return]  ${value}

Отримати інформацію із предмету
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  ${field_name}=  Set Variable If  '[' in '${field_name}'  ${field_name.split('[')[0]}${field_name.split(']')[1]}  ${field_name}
  ${value}=  Run Keyword If
  ...  'unit.code' in '${field_name}'  Log To Console   ${red}\n\t\t\t Це поле не виводиться на centrex
  ...  ELSE IF  'deliveryLocation' in '${field_name}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на centrex
  ...  ELSE IF  'unit' in '${field_name}'  Get Text  xpath=//i[contains(text(), '${item_id}')]/ancestor::div[@class="item no_border"]/descendant::*[@tid='items.quantity']
  ...  ELSE  Get Text  xpath=//i[contains(text(), '${item_id}')]/ancestor::div[@class="item no_border"]/descendant::*[@tid='items.${field_name}']
  ${value}=  adapt_view_item_data  ${value}  ${field_name}
  [return]  ${value}

Отримати кількість предметів в тендері
  [Arguments]  ${username}  ${tender_uaid}
  centrex.Пошук тендера по ідентифікатору   ${username}   ${tender_uaid}
  ${number_of_items}=  Get Matching Xpath Count  //div[@class="item no_border"]
  [return]  ${number_of_items}

Отримати інформацію із запитання
  [Arguments]  ${username}  ${tender_uaid}  ${question_id}  ${field_name}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Element Is Enabled  xpath=//a[@tid="sidebar.questions"]
  Click Element  xpath=//a[@tid="sidebar.questions"]
  ${value}=  Get Text  xpath=//h4[contains(text(),'${question_id}')]/../descendant::*[@tid='questions.${field_name}']
  [return]  ${value}

Отримати інформацію із пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${field}
  ${bid_value}=   Get Text   xpath=//div[contains(text(), 'Ваша ставка')]
  ${bid_value}=   Convert To Number   ${bid_value.split(' ')[-2]}
  [return]  ${bid_value}

Отримати інформацію із документа
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
  ${doc_value}=  Get Text  xpath=//a[contains(text(),'${doc_id}')]
  [return]  ${doc_value}

Отримати документ
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}
  ${file_name}=   Get Text   xpath=//a[contains(text(),'${doc_id}')]
  ${url}=   Get Element Attribute   xpath=//a[contains(text(),'${doc_id}')]@href
  centrex_download_file   ${url}  ${file_name}  ${OUTPUT_DIR}
  [return]  ${file_name}

Отримати кількість документів в тендері
  [Arguments]  ${username}  ${tender_uaid}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${number_of_documents}=  Get Matching Xpath Count  //div[@class="document"]
  [return]  ${number_of_documents}

Отримати інформацію із документа по індексу
  [Arguments]  ${username}  ${tender_uaid}  ${document_index}  ${field}
  centrex.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${doc_value}=  Get Text  xpath=(//div[@class="document"])[${document_index + 1}]/div[2]/div[2]/b/i
  ${doc_value}=  convert_string_from_dict_centrex  ${doc_value}
  [return]  ${doc_value}

###############################################################################################################
#######################################    ПОДАННЯ ПРОПОЗИЦІЙ    ##############################################
###############################################################################################################

Подати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  ${status}=  Get From Dictionary  ${bid['data']}  qualified
  ${file_path}=  get_upload_file_path
  centrex.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Wait Until Element Is Visible   xpath=//input[contains(@name, '[value][amount]')]
  ConvToStr And Input Text  xpath=//input[contains(@name, '[value][amount]')]  ${bid.data.value.amount}
  Choose File  name=FileUpload[file]  ${file_path}
  Run Keyword If  '${MODE}' == 'dgfFinancialAssets'
  ...  Select From List By Value  xpath=(//*[contains(@name,'[documentType]')])[last()]  financialLicense
  ...  ELSE  Select From List By Value  xpath=(//*[contains(@name,'[documentType]')])[last()]  commercialProposal
  Click Element  xpath=//button[contains(text(), 'Відправити')]
  Wait Until Element Is Visible  name=delete_bids
  ${url}=  Log Location
  Run Keyword If  ${status}
  ...  Go To  http://eauction.centrex.com.ua/bids/send/${url.split('?')[0].split('/')[-1]}
  ...  ELSE  Go To  http://eauction.centrex.com.ua/bids/decline/${url.split('?')[0].split('/')[-1]}
  Go To  ${url}
  Wait Until Keyword Succeeds  6 x  30 s  Run Keywords
  ...  Reload Page
  ...  AND  Page Should Contain  Статус - опублiковано

Скасувати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}
  centrex.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Execute Javascript  window.confirm = function(msg) { return true; }
  Click Element  xpath=//button[@name="delete_bids"]

Змінити цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  ${file_path}=  get_upload_file_path
  centrex.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  centrex.Скасувати цінову пропозицію  ${username}  ${tender_uaid}
  Wait Until Element Is Visible   xpath=//input[contains(@name, '[value][amount]')]
  ConvToStr And Input Text  xpath=//input[contains(@name, '[value][amount]')]  ${fieldvalue}
  Choose File  name=FileUpload[file]  ${file_path}
  Run Keyword If  '${MODE}' == 'dgfFinancialAssets'
  ...  Select From List By Value  xpath=(//*[contains(@name,'[documentType]')])[last()]  financialLicense
  ...  ELSE  Select From List By Value  xpath=(//*[contains(@name,'[documentType]')])[last()]  commercialProposal
  Click Element  xpath=//button[contains(text(), 'Відправити')]
  Wait Until Element Is Visible  name=delete_bids
  ${url}=  Log Location
  Go To  http://eauction.centrex.com.ua/bids/send/${url.split('?')[0].split('/')[-1]}
  Go To  ${url}

Завантажити документ в ставку
  [Arguments]  ${username}  ${path}  ${tender_uaid}  ${doc_type}=documents
  centrex.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${value}=  centrex.Отримати інформацію із пропозиції  ${username}  ${tender_uaid}  ${EMPTY}
  centrex.Скасувати цінову пропозицію  ${username}  ${tender_uaid}
  Wait Until Element Is Visible   xpath=//input[contains(@name, '[value][amount]')]
  ConvToStr And Input Text  xpath=//input[contains(@name, '[value][amount]')]  ${value}
  Choose File  name=FileUpload[file]  ${path}
  Run Keyword If  '${MODE}' == 'dgfFinancialAssets'
  ...  Select From List By Value  xpath=(//*[contains(@name,'[documentType]')])[last()]  financialLicense
  ...  ELSE  Select From List By Value  xpath=(//*[contains(@name,'[documentType]')])[last()]  commercialProposal
  Click Element  xpath=//button[contains(text(), 'Відправити')]
  Wait Until Element Is Visible  name=delete_bids
  ${url}=  Log Location
  Go To  http://eauction.centrex.com.ua/bids/send/${url.split('?')[0].split('/')[-1]}
  Go To  ${url}

Завантажити фінансову ліцензію
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  centrex.Завантажити документ в ставку  ${username}  ${filepath}  ${tender_uaid}

Змінити документ в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${path}  ${docid}
  centrex.Завантажити документ в ставку  ${username}  ${path}  ${tender_uaid}

###############################################################################################################
##############################################    АУКЦІОН    ##################################################
###############################################################################################################

Отримати посилання на аукціон для глядача
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=${Empty}
  centrex.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${auction_url}  Get Element Attribute  xpath=(//a[text()= 'Перебіг аукціону'])[1]@href
  [return]  ${auction_url}

Отримати посилання на аукціон для учасника
  [Arguments]  ${username}  ${tender_uaid}
  centrex.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${auction_url}  Get Element Attribute  xpath=(//a[text()= 'Перебіг аукціону'])[1]@href
  [return]  ${auction_url}


###############################################################################################################
###########################################    КВАЛІФІКАЦІЯ    ################################################
###############################################################################################################

Підтвердити постачальника
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}
  centrex.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Wait Until Keyword Succeeds   30 x   30 s  Run Keywords
  ...  Reload Page
  ...  AND  Click Element  xpath=//a[text()='Таблиця квалiфiкацiї']
  Wait Until Element Is Visible  xpath=//button[@name='protokol_ok']
  Click Element  xpath=//button[@name='protokol_ok']
  Wait Until Element Is Visible  xpath=//button[@data-bb-handler="confirm"]
  Click Element  xpath=//button[@data-bb-handler="confirm"]
  Wait Until Element Is Visible  xpath=//button[text()='Визнати переможцем']
  Click Element  xpath=//button[text()='Визнати переможцем']
  Wait Until Element Is Visible   xpath=//button[contains(@class, 'tender_contract_btn')]

Отримати кількість документів в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${bid_index}
  centrex.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Wait Until Element Is Visible  xpath=//a[text()='Таблиця квалiфiкацiї']
  Click Element  xpath=//a[text()='Таблиця квалiфiкацiї']
  ${disqualification_status}=  Run Keyword And Return Status  Wait Until Page Does Not Contain Element  xpath=//*[contains(text(),'Дисквалiфiковано')]  10
  Run Keyword If  ${disqualification_status}  Wait Until Keyword Succeeds  15 x  1 m  Run Keywords
  ...    Reload Page
  ...    AND  Wait Until Page Contains  auctionProtocol
  ...  ELSE  Wait Until Keyword Succeeds  15 x  1 m  Run Keywords
  ...    Reload Page
  ...    AND  Xpath Should Match X Times  //*[contains(text(),'auctionProtocol')]  2
  ${bid_doc_number}=   Get Matching Xpath Count   //td[contains(text(),'На розглядi ')]/../following-sibling::tr[2]/descendant::div[@class="bid_document_block"]/table/tbody/tr
  [return]  ${bid_doc_number}

Отримати дані із документу пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${bid_index}  ${document_index}  ${field}
  ${doc_value}=  Get Text  xpath=//div[@class="bid_document_block"]/table/tbody/tr[${document_index + 1}]/td[2]/span
  [return]  ${doc_value}

Завантажити протокол аукціону
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${award_index}
  Перейти на сторінку кваліфікації учасників  ${username}  ${tender_uaid}
  Choose File  name=FileUpload[file]  ${filepath}
  Wait Until Element Is Visible  xpath=//*[contains(@name,'[documentType]')]
  Select From List By Value  xpath=(//*[contains(@name,'[documentType]')])[last()]  auctionProtocol
  Click Element  id=submit_winner_files
  Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-success')]
  Wait Until Keyword Succeeds  15 x  1 m  Дочекатися завантаження файлу  ${filepath.split('/')[-1]}

Скасування рішення кваліфікаційної комісії
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}
  Перейти на сторінку кваліфікації учасників  ${username}  ${tender_uaid}
  Wait Until Element Is Enabled  xpath=//button[@data-type="cancelled"]
  Click Element  xpath=//button[@data-type="cancelled"]
  Wait Until Element Is Visible  name=btn_cancel
  Click Element  name=btn_cancel
  Wait Until Page Contains  Сторiнка оновиться автоматично  30
  Wait Until Page Does Not Contain  Сторiнка оновиться автоматично  60

Дискваліфікувати постачальника
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}  ${description}
  Click Element  xpath=(//input[@name="Award[cause][]"])[1]
  Click Element  xpath=//button[@name="send_prequalification"]
  Wait Until Page Contains  Дисквалiфiковано

Завантажити документ рішення кваліфікаційної комісії
  [Arguments]  ${username}  ${document}  ${tender_uaid}  ${award_num}
  Перейти на сторінку кваліфікації учасників  ${username}  ${tender_uaid}
  Choose File  name=FileUpload[file]  ${document}

Завантажити угоду до тендера
  [Arguments]  ${username}  ${tender_uaid}  ${contract_num}  ${filepath}
  Перейти на сторінку кваліфікації учасників   ${username}  ${tender_uaid}
  Click Element  xpath=//button[contains(@class, 'tender_contract_btn')]
  Choose File  name=FileUpload[file]  ${filepath}
  Click Element  xpath=(//button[text()='Завантажити'])[2]


Підтвердити підписання контракту
  [Arguments]  ${username}  ${tender_uaid}  ${contract_num}
  Перейти на сторінку кваліфікації учасників   ${username}  ${tender_uaid}
  Wait Until Keyword Succeeds  5 x  0.5 s  Click Element  xpath=//button[contains(@class, 'tender_contract_btn')]
  Wait Until Element Is Visible  xpath=(//input[contains(@name,"[contractNumber]")])[2]
  Wait Until Keyword Succeeds  5 x  1 s  Run Keywords
  ...  Input Text  xpath=(//input[contains(@name,"[contractNumber]")])[2]  777
  ...  AND  Choose Ok On Next Confirmation
  ...  AND  Click Element  xpath=(//button[text()='Активувати'])[2]
  ...  AND  Confirm Action

###############################################################################################################

ConvToStr And Input Text
  [Arguments]  ${elem_locator}  ${smth_to_input}
  ${smth_to_input}=  Convert To String  ${smth_to_input}
  Input Text  ${elem_locator}  ${smth_to_input}

Conv And Select From List By Value
  [Arguments]  ${elem_locator}  ${smth_to_select}
  ${smth_to_select}=  Convert To String  ${smth_to_select}
  ${smth_to_select}=  convert_string_from_dict_centrex  ${smth_to_select}
  Select From List By Value  ${elem_locator}  ${smth_to_select}

Input Date
  [Arguments]  ${elem_locator}  ${date}
  ${date}=  convert_datetime_to_centrex_format  ${date}
  Input Text  ${elem_locator}  ${date}

Дочекатися завантаження файлу
  [Arguments]  ${doc_name}
  Reload Page
  Wait Until Page Contains  ${doc_name}  10

Перейти на сторінку кваліфікації учасників
  [Arguments]  ${username}  ${tender_uaid}
  centrex.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Wait Until Element Is Visible  xpath=//a[text()='Таблиця квалiфiкацiї']
  Click Element  xpath=//a[text()='Таблиця квалiфiкацiї']
