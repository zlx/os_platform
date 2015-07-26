require 'minitest_helper'

class TestOSPlatform < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::OSPlatform::VERSION
  end
end
