#R webscrape fill out form. Captcha. do 1 year. 

library(RSelenium)
library(wdman)
library(netstat)
library(getPass)
library(magick)
library(dplyr)
library(tesseract)
library(tidyverse)

#Input version of chromedriver. 
remote_driver = rsDriver(browser = "chrome", chromever = "114.0.5735.90", verbose = FALSE, port = free_port())
remDr <- remote_driver[["client"]]
remDr$maxWindowSize()


##This is the link to go to. 
remDr$navigate('https://esearch.delhigovt.nic.in/Complete_search.aspx')

sro<-remDr$findElement(using = 'xpath', '//*[@id="ctl00_ContentPlaceHolder1_ddl_sro_s"]/option[19]')
sro$clickElement()

locality<-remDr$findElement(using = 'xpath', '//*[@id="ctl00_ContentPlaceHolder1_ddl_loc_s"]/option[61]')
locality$clickElement()
yr<- remDr$findElement(using = 'xpath', '//*[@id="ctl00_ContentPlaceHolder1_ddl_year_s"]/option[3]')
yr$clickElement()

#remDr1$refresh()

#Scroll to bottom
webElem <- remDr$findElement("css", "body")
webElem$sendKeysToElement(list(key = "end"))

library('base64enc')
screenshot<-remDr$screenshot(display = FALSE)# file = "screenshot.png")
screenshot <- base64decode(toString(screenshot), output = NULL)
screenshot <- image_read(screenshot)
image_info(screenshot);class(screenshot)

captcha<-image_crop(screenshot,"166X286+730+730+600") ;captcha
# captcha<-image_crop(screenshot,"240X100+800+420+600") 
png(filename="U:\\Documents\\consult_user_files\\ng482\\captcha.png")
plot(screenshot)#;captcha
dev.off()

#Testing. Get this to work on the workshop computer. Duplicated screen. Need to get this code working there. Just these params. 
captcha<-image_crop(screenshot,"160x50+650+585+600") ;captcha
# captcha<-image_crop(screenshot,"286x300(size of region. Keep consistent most likely.)+130(slides to left.)+330+600")
#Figure out which one is which. 
png(filename="U:\\Documents\\consult_user_files\\ng482\\captcha_test.png")
plot(captcha);captcha
dev.off()

remote_driver2 = rsDriver(browser = "chrome", chromever = "114.0.5735.90", verbose = FALSE, port = free_port())
remDr2 <- remote_driver2[["client"]]
remDr2$maxWindowSize()

remDr2$navigate("https://www.iloveocr.com/image-to-word")
upload<-remDr2$findElement(using = 'xpath', '/html/body/div[2]/div[2]/div[1]/div[4]/div[2]/div/div/input[2]')

path<-"U:\\Documents\\consult_user_files\\ng482\\captcha_test.png"
upload$sendKeysToElement(list(path))

Sys.sleep(5)
read_captcha<-remDr2$findElement(using = 'xpath', '/html/body/div[2]/div[2]/div[1]/div[6]/div[2]/div/button')
#/html/body/div[2]/div[2]/div[1]/div[6]/div[2]/div/button
read_captcha$clickElement()
Sys.sleep(15)

copy_captcha<-remDr2$findElement(using = 'xpath', '/html/body/div[2]/div[2]/div[1]/div[7]/div[4]/div[2]/div[1]/span/span[2]')
copy_captcha$clickElement()
paste_captcha<-paste(readClipboard(), collapse = ",")
paste_captcha<-str_squish(paste_captcha)
paste_captcha
#---------------Enter captcha and check if captcha entered while page loads-----------------------------------------------------------------------
write_captcha<-remDr$findElement(using ='xpath', '//*[@id="ctl00_ContentPlaceHolder1_txtcaptcha_s"]')
write_captcha$sendKeysToElement(list(paste_captcha))

enter<-remDr$findElement(using = 'xpath', '//*[@id="ctl00_ContentPlaceHolder1_btn_search_s"]')
enter$clickElement()


#Excellent! That is working. Now get the data in the table. Just 1 year would be fine all pages.
headings = remDr$findElements(using = 'tag', 'th')
heading_titles <- sapply(headings, function(x) x$getElementText())
columns <- as.vector(heading_titles)
myData <- data.frame(matrix(nrow = 0, ncol = length(columns))) 

#Get number of pages. 
pagecount<- remDr$findElements(using = "xpath", value ='//*[@id="ctl00_ContentPlaceHolder1_gv_search_ctl13_lblTotalNumberOfPages"]')
pages<- sapply(pagecount, function(x) x$getElementText())
pages<- as.numeric(pages); pages

table_data_rows = remDr$findElements(using = "xpath", value = "//*[@id='ctl00_ContentPlaceHolder1_gv_search']/tbody/tr")
# Append to the dataset. 
# Extract the first page.
for(i in 1:(length(table_data_rows) - 3)){
  string = paste("//*[@id='ctl00_ContentPlaceHolder1_gv_search']/tbody/tr[",i+1, "]/td", sep = "")
  table_data_cells = remDr$findElements(using = "xpath", value = string)
  row <- sapply(table_data_cells, function(x) x$getElementText())
  myData <- rbind(myData, row)
}

#Then do loop to remaining pages.
j = 1
while(j < pages) {
  webElem <- remDr$findElement("css", "body")
  webElem$sendKeysToElement(list(key = "end"))
  nxtpage<-remDr$findElement(using = 'name', 'ctl00$ContentPlaceHolder1$gv_search$ctl13$Button2')
  nxtpage$clickElement()
  Sys.sleep(2)
  j = j+1
  
  table_data_rows = remDr$findElements(using = "xpath", value = "//*[@id='ctl00_ContentPlaceHolder1_gv_search']/tbody/tr")
  for(i in 1:(length(table_data_rows) - 3)){
    string = paste("//*[@id='ctl00_ContentPlaceHolder1_gv_search']/tbody/tr[",i+1, "]/td", sep = "")
    table_data_cells = remDr$findElements(using = "xpath", value = string)
    row <- sapply(table_data_cells, function(x) x$getElementText())
    myData <- rbind(myData, row)
  }
  
}

colnames(myData) = columns

#Export dataset
write.csv(myData, file = "results23-24.csv")
