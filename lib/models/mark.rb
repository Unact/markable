module Markable
  class Mark < ActiveRecord::Base
    belongs_to :markable, :polymorphic => true
    belongs_to :marker, :polymorphic => true

    # Delete orphan marks
    #
    # Marks are deleted when marker or markable record is destroyed. However, in some circumstances, some marks
    # may reference non existing records (for instance if the record has been deleted - not destroyed).
    #
    # Note: this method is not efficient but this should not be a problem as it should be used as a maintenance
    # operation only.
    #
    # @return [Number] Deleted orphan marks count
    def self.delete_orphans
      Markable::Mark.all.to_a.delete_if { |mark|
        mark.marker && mark.markable
      }.each(&:delete).count
    end
  end
end
