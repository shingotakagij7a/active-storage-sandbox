require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "valid factory" do
    post = Post.new(title: "Hello", body: "World")
    assert post.valid?
  end

  test "requires title" do
    post = Post.new(body: "Body only")
    refute post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end
end
