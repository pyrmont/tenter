# frozen_string_literal: true

require "minitest/autorun"
require "rack/test"

require "tenter"

class TenterTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Tenter::Hooks
  end

  def path(command, dir)
    "/run/#{command}/in/#{dir}/"
  end

  def valid_sig
    { "HTTP_X_HUB_SIGNATURE" => "sha1=f56231a012c446e4bc544ef393579448de7f31f4" }
  end

  def setup
    Tenter.settings = { doc_root: File.join(__dir__, "data") }
  end

  def teardown
    Tenter.reset
    File.write(File.join(__dir__, "data/some_dir/log/commands.log"), "")
  end

  def test_default_settings
    assert_equal [ :command_dir, :config_filename, :doc_root, :log_file,
                   :timestamp ],
                 Tenter.settings.keys.sort
  end

  def test_custom_settings
    Tenter.settings = { doc_root: "doc_root" }
    assert_equal "doc_root", Tenter.settings[:doc_root]
  end

  def test_root
    get "/"
    assert_equal 404, last_response.status
    assert_equal "Page not found", last_response.body
  end

  def test_post_with_no_signature
    post path("cmd", "some_dir")
    assert_equal 400, last_response.status
    assert_equal "X-Hub-Signature header not set", last_response.body
  end

  def test_post_with_invalid_signature
    post path("cmd", "some_dir"), nil, { "HTTP_X_HUB_SIGNATURE" => "invalid" }
    assert_equal 403, last_response.status
    assert_equal "X-Hub-Signature header did not match", last_response.body
  end

  def test_post_with_invalid_dir
    post path("cmd", "other_dir"), nil, valid_sig
    assert_equal 403, last_response.status
    assert_equal "X-Hub-Signature header did not match", last_response.body
  end

  def test_post_with_invalid_command
    post path("other_cmd", "some_dir"), nil, valid_sig
    assert_equal 400, last_response.status
    assert_equal "Command not found", last_response.body
  end

  def test_post_with_valid_command
    command = Tenter::Utils.command "cmd", "some_dir"
    statement = "Initiating: #{command["path"]}"
    time_re = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \+\d{4}/
    re = /\[#{time_re}\] #{statement}\n\[#{time_re}\] Hello world\n/

    post path("cmd", "some_dir"), nil, valid_sig
    assert_equal 200, last_response.status
    assert_equal "Command initiated", last_response.body
    assert_equal 0, re =~ File.read(command["log"])
  end

  def test_post_with_no_log
    Tenter.settings = { log_file: nil }
    post path("cmd", "some_dir"), nil, valid_sig
    assert_equal 200, last_response.status
    assert_equal "Command initiated", last_response.body
    assert_equal "", File.read(File.join(Tenter.settings[:doc_root], "some_dir",
                                         Tenter.defaults[:log_file]))
  end
end
