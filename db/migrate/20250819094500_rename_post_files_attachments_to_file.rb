class RenamePostFilesAttachmentsToFile < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    say_with_time "Renaming ActiveStorage attachments name=files -> file for Post" do
      execute <<~SQL
        UPDATE active_storage_attachments
        SET name = 'file'
        WHERE record_type = 'Post' AND name = 'files'
      SQL
    end
  end

  def down
    say_with_time "Reverting ActiveStorage attachments name=file -> files for Post" do
      execute <<~SQL
        UPDATE active_storage_attachments
        SET name = 'files'
        WHERE record_type = 'Post' AND name = 'file'
      SQL
    end
  end
end
