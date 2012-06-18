require "selenium-webdriver"
require "test/unit"

class SoftwareTest < Test::Unit::TestCase

  def setup
    @driver = Selenium::WebDriver.for :firefox
    @base_url = "http://ec2-54-248-14-4.ap-northeast-1.compute.amazonaws.com/"
    @driver.manage.timeouts.implicit_wait = 60
    @verification_errors = []
    @timeout = 600
    @page_name = "//*[@id='center-div']/h1"
    @table = "//*[@id='center-div']/table/tbody"
    @base_tr = 2
    @node_name = "td[1]"
    @node_state = "td[2]"
    @proposal_name = "td[2]"
    @proposal_software = "td[3]"
    @proposal_state = "td[4]"
  end
  
  def teardown
    @driver.quit
    assert_equal [], @verification_errors
  end
  
  def test_software

    # sign in
    email = "ipride.kakumoto@gmail.com"
    pass = "intellilink"
    sign_in(email, pass)

    # add Node
    node_name = "ubuntu2"
    add_node(node_name)

    # add Proposal hadoop 0.20.2, sun grid engine 6.2u5
    proposal_name = "hadoop"
    software_name = "hadoop 0.20.2"
    add_proposal(proposal_name, software_name)

    # install hadoop
    execute("install")

    # test hadoop
    execute("test")

    # uninstall hadoop
    execute("uninstall")

    # delete proposal, delete node
    clean_up()

    # sign out
    sign_out()

  end
  
  def element_present?(how, what)
    @driver.find_element(how, what)
    true
  rescue Selenium::WebDriver::Error::NoSuchElementError
    false
  end
  
  def verify(&blk)
    yield
  rescue Test::Unit::AssertionFailedError => ex
    @verification_errors << ex
  end

  def sign_in(email, pass)
    @driver.get(@base_url + "/users/sign_in")
    assert_equal "Sign in", @driver.find_element(:xpath, "//*[@id='ui-dialog-title-center-div']").text
    @driver.find_element(:xpath, "//*[@id='user_email']").clear
    @driver.find_element(:xpath, "//*[@id='user_email']").send_keys email
    @driver.find_element(:xpath, "//*[@id='user_password']").clear
    @driver.find_element(:xpath, "//*[@id='user_password']").send_keys pass
    @driver.find_element(:xpath, "//*[@id='user_submit']").click
    assert_equal "Signed in as #{email}. Not you? Sign out", @driver.find_element(:xpath, "//*[@id='sign-in']").text
  end

  def add_node(node_name)
    @driver.find_element(:link, "Nodes").click
    assert_equal "Listing nodes", @driver.find_element(:xpath, @page_name).text
    @driver.find_element(:link, "New Node").click
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "//*[@id='node_name']")).select_by(:text, node_name)
    @driver.find_element(:xpath, "//*[@id='node_submit']").click
    assert_equal "Listing nodes", @driver.find_element(:xpath, @page_name).text
    assert_equal node_name, @driver.find_element(:xpath, "#{@table}/tr[#{@base_tr}]/#{@node_name}").text
    assert_equal "available", @driver.find_element(:xpath, "#{@table}/tr[#{@base_tr}]/#{@node_state}").text
  end

  def add_proposal(proposal_name, software_name)
    @driver.find_element(:link, "Proposals").click
    assert_equal "Listing proposals", @driver.find_element(:xpath, @page_name).text
    @driver.find_element(:link, "New proposal").click
    assert_equal "New proposal", @driver.find_element(:xpath, @page_name).text
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "//*[@id='proposal_software_id']")).select_by(:text, software_name)
    @driver.find_element(:xpath, "//*[@id='proposal_name']").clear
    @driver.find_element(:xpath, "//*[@id='proposal_name']").send_keys proposal_name
    @driver.find_element(:xpath, "//*[@id='proposal_submit']").click
    assert_equal proposal_name, @driver.find_element(:xpath, "#{@table}/tr[#{@base_tr}]/#{@proposal_name}").text
    assert_equal software_name, @driver.find_element(:xpath, "#{@table}/tr[#{@base_tr}]/#{@proposal_software}").text
    assert_equal "init ", @driver.find_element(:xpath, "#{@table}/tr[#{@base_tr}]/#{@proposal_state}").text
  end

  def execute(action)
    @driver.find_element(:xpath, "(//a[contains(text(),'#{action.capitalize}')][1])").click

    assert !@timeout.times{ break if (@driver.find_element(:xpath, "#{@table}/tr[#{@base_tr}]/#{@proposal_state}").text == "#{action}ing " rescue false); sleep 1 }

    if (action == "uninstall")
      assert !@timeout.times{ break if (@driver.find_element(:xpath, "#{@table}/tr[#{@base_tr}]/#{@proposal_state}").text == "init " rescue false); sleep 1 }
    else
      assert !@timeout.times{ break if (@driver.find_element(:xpath, "#{@table}/tr[#{@base_tr}]/#{@proposal_state}").text == "#{action}ed " rescue false); sleep 1 }
    end
  end

  def clean_up()
    # delete proposal
    @driver.find_element(:xpath, "(//a[contains(text(), 'Destroy')])").click
    sleep 2
    a = @driver.switch_to.alert
    a.accept
    assert_equal "Name Software State", @driver.find_element(:xpath, @table).text

    # delete node
    @driver.find_element(:link, "Nodes").click
    assert_equal "Listing nodes", @driver.find_element(:xpath, @page_name).text
    @driver.find_element(:xpath, "(//a[contains(text(), 'Destroy')])").click
    sleep 2
    a = @driver.switch_to.alert
    a.accept
    assert_equal "Name State", @driver.find_element(:xpath, @table).text
  end

  def sign_out()
    @driver.find_element(:link, "Sign out").click
    assert_equal "Sign in", @driver.find_element(:xpath, "//*[@id='ui-dialog-title-center-div']").text
  end

end
