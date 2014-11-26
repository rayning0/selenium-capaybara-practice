# By Raymond Gan
# Search 3 health insurance sites for a health provider's name

require 'selenium-webdriver'

class DocSearch
  attr_reader :docname, :location, :wait

  BLUESHIELD = "https://www.blueshieldca.com/fap/app/search.html"
  CIGNA = "http://www.cigna.com/web/public/hcpdirectory"
  ANTHEM = "https://www.anthem.com/health-insurance/provider-directory/searchcriteria?qs=*oSNAkuPxSiuUjQfgYjX36w==&brand=abc"

  def initialize
    @wait = Selenium::WebDriver::Wait.new(timeout: 25)
  end

  def in_blue_shield?
    d = Selenium::WebDriver.for(:chrome)
    d.navigate.to(BLUESHIELD)
    lname, fname = docname.split(',').map(&:strip)

    d.find_element(id: "doctorsAdvancedSearch").click
    d.find_element(id: "doctorLName").click
    sleep(1)
    d.find_element(id: "doctorLName").send_keys(lname)
    d.find_element(id: "doctorFName").click
    sleep(1)
    d.find_element(id: "doctorFName").send_keys(fname)
    d.find_element(id: "location").send_keys(location)
    d.find_element(id: "findNowButton").click
    sleep(2)
    d.find_element(class: "continueBtn").click

    wait.until { d.find_element(id: "refreshDateId") }
    sleep(2)
    d.find_elements(class: 'docName').find do |doctor|
      return true if doctor.text.upcase.include?(docname)
    end
    false
  end

  def in_cigna?
    d = Selenium::WebDriver.for(:chrome)
    d.navigate.to(CIGNA)

    d.find_elements(tag_name: "option").find do |option|
      option.click if option.text == "Person By Name"
    end

    d.find_element(name: "lookingForText").send_keys(docname)

    # look for popup. try to close it.
    begin
      if d.find_element(id: "oo_close_prompt")  # for Cigna
        d.find_element(id: "oo_close_prompt").click
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError # popup window not there
    ensure
      d.find_element(id: "searchLocation").send_keys(location)
      d.find_element(id: "searchLocBtn").click

      wait.until { d.find_element(class: "page-subtitle") }
      sleep(2)

      d.find_elements(class: 'profile-name').find do |doctor|
        return true if doctor.text.upcase.include?(docname)
      end
      false
    end
  end

  def in_anthem?
    d = Selenium::WebDriver.for(:chrome)
    d.navigate.to(ANTHEM)
    @docname = docname.split(',').reverse.join(' ').strip

    d.find_element(id: "ctl00_MainContent_maincontent_SearchWizard6_LastName")
      .send_keys(docname)

    d.find_elements(tag_name: "option").find do |option|
      if option.text == "All Specialties"
        option.click
        break
      end
    end

    d.find_element(id: "ctl00_MainContent_maincontent_SearchWizard6_SearchWizard5_txtZipCityState")
      .send_keys(location.upcase)
    d.find_element(id: "ctl00_MainContent_maincontent_SearchWizard7_rbNot").click
    d.find_element(id: "btnSearch").click

    wait.until { d.find_element(class: "fsrFloatingContainer") }  # wait for popup
    sleep(2)
    begin
      if d.find_element(class: "fsrFloatingContainer")
        d.find_element(class: "fsrCloseBtn").click  # close popup
      end

    # popup window not there
    rescue [Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::TimeOutError]

    ensure
      wait.until { d.find_element(class: "disclaimerItem") }
      d.find_elements(class: 'lnkname').find do |doctor|
        return true if doctor.text.upcase.include?(docname)
      end
      false
    end
  end

  def run
    get_input

    ['blue_shield', 'cigna', 'anthem'].each do |network|
      if self.send("in_#{network}?")
        puts "He/she is in #{titleize(network)} network in #{location}"
      else
        puts "He/she is NOT in #{titleize(network)} network in #{location}"
      end
    end
  end

  private

  def titleize(word)
    word.gsub('_', ' ').split.map(&:capitalize)*' '
  end

  def get_input
    print "Enter doctor name (last, first. Enter gives default: Smith, Kathleen): "
    @docname = gets.strip.upcase
    @docname = 'SMITH, KATHLEEN' if @docname.empty?
    print "Enter city, state (Enter gives default: San Francisco, CA): "
    @location = gets.strip.upcase
    @location = 'SAN FRANCISCO, CA' if @location.empty?
  end
end

DocSearch.new.run

# Screen output:

# Enter doctor name (last, first. Enter gives default: Smith, Kathleen):
# Enter city, state (Enter gives default: San Francisco, CA):

# He/she is in Blue Shield network in SAN FRANCISCO, CA
# He/she is in Cigna network in SAN FRANCISCO, CA
# He/she is in Anthem network in SAN FRANCISCO, CA