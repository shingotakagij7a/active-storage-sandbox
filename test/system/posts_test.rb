require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  test "create post" do
    visit posts_path
    fill_in "Title", with: "First Post"
  fill_in "Body", with: "This is the body"
  attach_file "Attachment", Rails.root.join("test/fixtures/files/rails.png"), make_visible: true
    click_on "Create Post"

    assert_text "Post was successfully created."
    assert_text "First Post"
    assert_text "This is the body"
  assert_link "rails.png"
  end
end
