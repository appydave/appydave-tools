# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      module Models
        # Configuration model for Youtube automation
        class YoutubeAutomationConfig < ConfigBase
          def workflow_groups
            data['workflow_groups'].map do |group|
              WorkflowGroup.new(group)
            end
          end

          def workflow_steps
            data['workflow_steps'].map do |step|
              WorkflowStep.new(step)
            end
          end

          def get_workflow_group(group_id)
            group_data = data['workflow_groups'].find { |group| group['group'] == group_id }
            WorkflowGroup.new(group_data) if group_data
          end

          def get_workflow_steps(group_id)
            data['workflow_steps'].select { |step| step['group'] == group_id }.map do |step|
              WorkflowStep.new(step)
            end
          end

          def get_sequence(sequence)
            group, seq = sequence.split('-')
            workflow_steps.find { |step| step.group == group && step.sequence == seq }
          end

          def next_sequence(sequence)
            group, seq = sequence.split('-')
            current_index = workflow_steps.find_index { |step| step.group == group && step.sequence == seq }
            workflow_steps[current_index + 1] if current_index && current_index < workflow_steps.size - 1
          end

          def previous_sequence(sequence)
            group, seq = sequence.split('-')
            current_index = workflow_steps.find_index { |step| step.group == group && step.sequence == seq }
            workflow_steps[current_index - 1] if current_index&.positive?
          end

          private

          def default_data
            {
              'workflow_groups' => [],
              'workflow_steps' => []
            }
          end

          # Model for workflow groups
          class WorkflowGroup
            attr_accessor :group, :description

            def initialize(data)
              @group = data['group']
              @description = data['description']
            end

            def to_h
              {
                'group' => @group,
                'description' => @description
              }
            end
          end

          # Model for workflow steps
          class WorkflowStep
            attr_accessor :group, :sequence, :name, :description

            def initialize(data)
              @group = data['group']
              @sequence = data['sequence']
              @name = data['name']
              @description = data['description']
            end

            def filename(ext)
              "#{@group}-#{@sequence}-#{@name}.#{ext}"
            end

            def to_h
              {
                'group' => @group,
                'sequence' => @sequence,
                'name' => @name,
                'description' => @description
              }
            end
          end
        end
      end
    end
  end
end
