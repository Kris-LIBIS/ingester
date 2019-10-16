# frozen_string_literal: true

require_relative 'spec_helper'

require 'stringio'
require 'awesome_print'
require 'active_support/core_ext/hash/reverse_merge'

basedir = File.absolute_path File.join(__dir__)
datadir = File.join(basedir, 'data')
taskdir = File.join(basedir, 'tasks')

def check_output(logoutput, sample_out)
  sample_out = sample_out.lines.to_a.map(&:strip)
  output = logoutput.string.lines.to_a.map { |x| x[/(?<=\] ).*/] }

  puts 'output:'
  puts output.join("\n")

  expect(output.size).to eq sample_out.size
  output.each_with_index do |o, i|
    expect(o.strip).to eq sample_out[i]
  end
end

def check_status_log(status_log, sample_status_log)
  status_log = status_log.map(&:pretty)
  puts 'status_log:'
  puts(status_log.map do |log|
    "{task: '%<task>s', status: :%<status>s, progress: %<progress>d, max: %<max>d}" % log
  end.join(",\n"))
  expect(status_log.size).to eq sample_status_log.size
  sample_status_log.each_with_index do |h, i|
    h.keys.each do |key|
      # puts "key: #{key} : #{status_log[i][key]} <=> #{h[key]}"
      expect(status_log[i][key]).to eq h[key]
    end
  end
end

context 'Workflow' do
  before :each do
    # noinspection RubyResolve
    Teneo::Ingester.configure do |cfg|
      cfg.taskdir = taskdir
      cfg.logger.appenders =
          ::Logging::Appenders.string_io('StringIO', layout: ::Teneo::Ingester::Config.get_log_formatter)
      cfg.logger.level = :DEBUG
      Teneo::Ingester::Config.require_all cfg.taskdir
    end
  end

  let(:logoutput) { ::Teneo::Ingester::Config.logger.appenders.first.sio }

  let(:processing) { 'success' }
  let(:force_run) { false }

  let(:job) do
    job = Teneo::DataModel::Package.create(
        name: 'IA1-1',
        ingest_workflow: Teneo::DataModel::IngestWorkflow.find_by(name: 'IA1workflow')
    )
    job.add_parameter(name: 'location', default: datadir, targets: %w'IA1workflow#location')
    job.add_parameter(name: 'checksum_algo', default: 'SHA256', targets: %w'IA1workflow#checksum_algo')
    job.add_parameter(name: 'processing', default: processing, targets: %w'IA1workflow#processing')
    job.add_parameter(name: 'force_run', default: force_run, targets: %w'IA1workflow#run_always')
    job
  end

  let(:run) { job.execute }

  context 'without forcing final task' do
    context 'when performing with success' do

      it 'should contain five stage tasks' do
        tasks_info = job.tasks
        expect(tasks_info.size).to eq 5
        expect(tasks_info.first[:name]).to eq 'Collect'
        expect(tasks_info.last[:name]).to eq 'PostIngest'
      end

      # noinspection RubyResolve
      it 'should camelize the workitem name' do
        run

        expect(run.config[:tasks].first[:tasks].first[:parameters][:location]).to eq datadir
        expect(job.items.size).to eq 1
        expect(job.items.first.class).to eq Teneo::Ingester::DirItem
        expect(job.items.first.size).to eq 3
        expect(job.items.first.items.size).to eq 3
        expect(job.items.first.items.first.class).to eq Teneo::Ingester::FileItem

        expect(job.items.first.name).to eq 'Abc'

        job.items.first.items.each_with_index do |x, i|
          expect(x.name).to eq %w[MyFile1.txt MyFile2.txt MyFile3.txt][i]
        end
      end

      it 'should return expected debug output' do
        run

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/5): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/5): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
          DEBUG -- PreProcess/ChecksumTester - IA1-1 : Processing subitem (1/1): abc
          DEBUG -- PreProcess/ChecksumTester - abc : Processing subitem (1/3): my_file_1.txt
          DEBUG -- PreProcess/ChecksumTester - abc : Processing subitem (2/3): my_file_2.txt
          DEBUG -- PreProcess/ChecksumTester - abc : Processing subitem (3/3): my_file_3.txt
          DEBUG -- PreProcess/ChecksumTester - abc : 3 of 3 subitems passed
          DEBUG -- PreProcess/ChecksumTester - IA1-1 : 1 of 1 subitems passed
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/5): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
          DEBUG -- PreIngest/CamelizeName - IA1-1 : Processing subitem (1/1): abc
          DEBUG -- PreIngest/CamelizeName - Abc : Processing subitem (1/3): my_file_1.txt
          DEBUG -- PreIngest/CamelizeName - Abc : Processing subitem (2/3): my_file_2.txt
          DEBUG -- PreIngest/CamelizeName - Abc : Processing subitem (3/3): my_file_3.txt
          DEBUG -- PreIngest/CamelizeName - Abc : 3 of 3 subitems passed
          DEBUG -- PreIngest/CamelizeName - IA1-1 : 1 of 1 subitems passed
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/5): Ingest
           INFO -- Ingest - IA1-1 : Running subtask (1/1): ProcessingTask
          DEBUG -- Ingest/ProcessingTask - IA1-1 : Processing subitem (1/1): Abc
          DEBUG -- Ingest/ProcessingTask - Abc : Processing subitem (1/3): MyFile1.txt
           INFO -- Ingest/ProcessingTask - Abc/MyFile1.txt : Task success
          DEBUG -- Ingest/ProcessingTask - Abc : Processing subitem (2/3): MyFile2.txt
           INFO -- Ingest/ProcessingTask - Abc/MyFile2.txt : Task success
          DEBUG -- Ingest/ProcessingTask - Abc : Processing subitem (3/3): MyFile3.txt
           INFO -- Ingest/ProcessingTask - Abc/MyFile3.txt : Task success
          DEBUG -- Ingest/ProcessingTask - Abc : 3 of 3 subitems passed
          DEBUG -- Ingest/ProcessingTask - IA1-1 : 1 of 1 subitems passed
           INFO -- Ingest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (5/5): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/1): FinalTask
          DEBUG -- PostIngest/FinalTask - IA1-1 : Processing subitem (1/1): Abc
          DEBUG -- PostIngest/FinalTask - Abc : Processing subitem (1/3): MyFile1.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile1.txt
          DEBUG -- PostIngest/FinalTask - Abc : Processing subitem (2/3): MyFile2.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile2.txt
          DEBUG -- PostIngest/FinalTask - Abc : Processing subitem (3/3): MyFile3.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile3.txt
          DEBUG -- PostIngest/FinalTask - Abc : 3 of 3 subitems passed
          DEBUG -- PostIngest/FinalTask - IA1-1 : 1 of 1 subitems passed
           INFO -- PostIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Done
        STR

        check_status_log run.status_log, [
            { task: 'Run', status: :done, progress: 5, max: 5 },
            { task: 'Collect', status: :done, progress: 1, max: 1 },
            { task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0 },
            { task: 'PreProcess', status: :done, progress: 1, max: 1 },
            { task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1 },
            { task: 'PreIngest', status: :done, progress: 1, max: 1 },
            { task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1 },
            { task: 'Ingest', status: :done, progress: 1, max: 1 },
            { task: 'Ingest/ProcessingTask', status: :done, progress: 1, max: 1 },
            { task: 'PostIngest', status: :done, progress: 1, max: 1 },
            { task: 'PostIngest/FinalTask', status: :done, progress: 1, max: 1 }
        ]

        check_status_log job.items.first.status_log, [
            { task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3 },
            { task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3 },
            { task: 'Ingest/ProcessingTask', status: :done, progress: 3, max: 3 },
            { task: 'PostIngest/FinalTask', status: :done, progress: 3, max: 3 }
        ]

        check_status_log job.items.first.items.first.status_log, [
            { task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0 },
            { task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0 },
            { task: 'Ingest/ProcessingTask', status: :done, progress: 0, max: 0 },
            { task: 'PostIngest/FinalTask', status: :done, progress: 0, max: 0 }
        ]
      end
    end

    context 'when stopped with async_halt' do
      let(:processing) { 'async_halt' }

      it 'should not run final task' do
        run

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/5): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/5): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
          DEBUG -- PreProcess/ChecksumTester - IA1-1 : Processing subitem (1/1): abc
          DEBUG -- PreProcess/ChecksumTester - abc : Processing subitem (1/3): my_file_1.txt
          DEBUG -- PreProcess/ChecksumTester - abc : Processing subitem (2/3): my_file_2.txt
          DEBUG -- PreProcess/ChecksumTester - abc : Processing subitem (3/3): my_file_3.txt
          DEBUG -- PreProcess/ChecksumTester - abc : 3 of 3 subitems passed
          DEBUG -- PreProcess/ChecksumTester - IA1-1 : 1 of 1 subitems passed
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/5): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
          DEBUG -- PreIngest/CamelizeName - IA1-1 : Processing subitem (1/1): abc
          DEBUG -- PreIngest/CamelizeName - Abc : Processing subitem (1/3): my_file_1.txt
          DEBUG -- PreIngest/CamelizeName - Abc : Processing subitem (2/3): my_file_2.txt
          DEBUG -- PreIngest/CamelizeName - Abc : Processing subitem (3/3): my_file_3.txt
          DEBUG -- PreIngest/CamelizeName - Abc : 3 of 3 subitems passed
          DEBUG -- PreIngest/CamelizeName - IA1-1 : 1 of 1 subitems passed
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/5): Ingest
           INFO -- Ingest - IA1-1 : Running subtask (1/1): ProcessingTask
          DEBUG -- Ingest/ProcessingTask - IA1-1 : Processing subitem (1/1): Abc
          DEBUG -- Ingest/ProcessingTask - Abc : Processing subitem (1/3): MyFile1.txt
          ERROR -- Ingest/ProcessingTask - Abc/MyFile1.txt : Task failed with async_halt status
          DEBUG -- Ingest/ProcessingTask - Abc : Processing subitem (2/3): MyFile2.txt
          ERROR -- Ingest/ProcessingTask - Abc/MyFile2.txt : Task failed with async_halt status
          DEBUG -- Ingest/ProcessingTask - Abc : Processing subitem (3/3): MyFile3.txt
          ERROR -- Ingest/ProcessingTask - Abc/MyFile3.txt : Task failed with async_halt status
          DEBUG -- Ingest/ProcessingTask - Abc : 0 of 3 subitems passed
           WARN -- Ingest/ProcessingTask - Abc : 3 subitem(s) halted in async process
          DEBUG -- Ingest/ProcessingTask - IA1-1 : 0 of 1 subitems passed
           WARN -- Ingest/ProcessingTask - IA1-1 : 1 subitem(s) halted in async process
           WARN -- Ingest - IA1-1 : 1 subtask(s) halted in async process
           INFO -- Ingest - IA1-1 : Remote process failed
           WARN -- Run - IA1-1 : 1 subtask(s) halted in async process
           INFO -- Run - IA1-1 : Remote process failed
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :async_halt, progress: 4, max: 5},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'Ingest', status: :async_halt, progress: 1, max: 1},
            {task: 'Ingest/ProcessingTask', status: :async_halt, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'Ingest/ProcessingTask', status: :async_halt, progress: 3, max: 3}
        ]

        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'Ingest/ProcessingTask', status: :async_halt, progress: 0, max: 0}
        ]
      end
    end

    context 'when stopped with fail' do
      let(:processing) { 'fail' }

      it 'should not run final task' do
        run

        check_output logoutput, <<~STR
           INFO -- Run - TestJob : Ingest run started.
           INFO -- Run - TestJob : Running subtask (1/3): CollectFiles
           INFO -- Run - TestJob : Running subtask (2/3): ProcessingTask
          ERROR -- ProcessingTask - test_dir_item.rb : Task failed with failed status
          ERROR -- ProcessingTask - test_file_item.rb : Task failed with failed status
          ERROR -- ProcessingTask - test_work_item.rb : Task failed with failed status
          ERROR -- ProcessingTask - TestJob : 3 subitem(s) failed
          ERROR -- Run - TestJob : 1 subtask(s) failed
           INFO -- Run - TestJob : Failed
        STR

        check_status_log run.status_log, [
            { task: 'Run', status: :failed, progress: 2, max: 3 },
            { task: 'CollectFiles', status: :done, progress: 3, max: 3 },
            { task: 'ProcessingTask', status: :failed, progress: 3, max: 3 }
        ]

        check_status_log job.items.first.status_log, [
            { task: 'CollectFiles', status: :done },
            { task: 'ProcessingTask', status: :failed }
        ]
      end
    end

    context 'when stopped with error' do
      let(:processing) { 'error' }

      it 'should not run final task' do
        run

        check_output logoutput, <<~STR
           INFO -- Run - TestJob : Ingest run started.
           INFO -- Run - TestJob : Running subtask (1/3): CollectFiles
           INFO -- Run - TestJob : Running subtask (2/3): ProcessingTask
          ERROR -- ProcessingTask - test_dir_item.rb : Error processing subitem (1/3): Task failed with WorkflowError exception
          ERROR -- ProcessingTask - test_file_item.rb : Error processing subitem (2/3): Task failed with WorkflowError exception
          ERROR -- ProcessingTask - test_work_item.rb : Error processing subitem (3/3): Task failed with WorkflowError exception
          ERROR -- ProcessingTask - TestJob : 3 subitem(s) failed
          ERROR -- Run - TestJob : 1 subtask(s) failed
           INFO -- Run - TestJob : Failed
        STR

        check_status_log run.status_log, [
            { task: 'Run', status: :failed, progress: 2, max: 3 },
            { task: 'CollectFiles', status: :done, progress: 3, max: 3 },
            { task: 'ProcessingTask', status: :failed, progress: 0, max: 3 }
        ]

        check_status_log job.items.first.status_log, [
            { task: 'CollectFiles', status: :done },
            { task: 'ProcessingTask', status: :failed }
        ]
      end
    end

    context 'when stopped with abort' do
      let(:processing) { 'abort' }

      it 'should not run final task' do
        run

        check_output logoutput, <<~STR
           INFO -- Run - TestJob : Ingest run started.
           INFO -- Run - TestJob : Running subtask (1/3): CollectFiles
           INFO -- Run - TestJob : Running subtask (2/3): ProcessingTask
          FATAL -- ProcessingTask - test_dir_item.rb : Fatal error processing subitem (1/3): Task failed with WorkflowAbort exception
          ERROR -- ProcessingTask - TestJob : 1 subitem(s) failed
          ERROR -- Run - TestJob : 1 subtask(s) failed
           INFO -- Run - TestJob : Failed
        STR

        check_status_log run.status_log, [
            { task: 'Run', status: :failed, progress: 2, max: 3 },
            { task: 'CollectFiles', status: :done, progress: 3, max: 3 },
            { task: 'ProcessingTask', status: :failed, progress: 0, max: 3 }
        ]

        check_status_log job.items.first.status_log, [
            { task: 'CollectFiles', status: :done },
            { task: 'ProcessingTask', status: :failed }
        ]
      end
    end
  end

  context 'with forcing final task' do
    let(:force_run) { true }

    context 'when processing successfully' do
      let(:processing) { 'success' }

      it 'should run final task' do
        run

        check_output logoutput, <<~STR
          INFO -- Run - TestJob : Ingest run started.
          INFO -- Run - TestJob : Running subtask (1/3): CollectFiles
          INFO -- Run - TestJob : Running subtask (2/3): ProcessingTask
          INFO -- ProcessingTask - test_dir_item.rb : Task success
          INFO -- ProcessingTask - test_file_item.rb : Task success
          INFO -- ProcessingTask - test_work_item.rb : Task success
          INFO -- Run - TestJob : Running subtask (3/3): FinalTask
          INFO -- FinalTask : Final processing of test_dir_item.rb
          INFO -- FinalTask : Final processing of test_file_item.rb
          INFO -- FinalTask : Final processing of test_work_item.rb
          INFO -- Run - TestJob : Done
        STR

        check_status_log run.status_log, [
            { task: 'Run', status: :done, progress: 3, max: 3 },
            { task: 'CollectFiles', status: :done, progress: 3, max: 3 },
            { task: 'ProcessingTask', status: :done, progress: 3, max: 3 },
            { task: 'FinalTask', status: :done, progress: 3, max: 3 }
        ]

        check_status_log job.items.first.status_log, [
            { task: 'CollectFiles', status: :done },
            { task: 'ProcessingTask', status: :done },
            { task: 'FinalTask', status: :done }
        ]
      end
    end

    context 'when stopped with async_halt' do
      let(:processing) { 'async_halt' }

      it 'should run final task' do
        run

        check_output logoutput, <<~STR
           INFO -- Run - TestJob : Ingest run started.
           INFO -- Run - TestJob : Running subtask (1/3): CollectFiles
           INFO -- Run - TestJob : Running subtask (2/3): ProcessingTask
          ERROR -- ProcessingTask - test_dir_item.rb : Task failed with async_halt status
          ERROR -- ProcessingTask - test_file_item.rb : Task failed with async_halt status
          ERROR -- ProcessingTask - test_work_item.rb : Task failed with async_halt status
           WARN -- ProcessingTask - TestJob : 3 subitem(s) halted in async process
           INFO -- Run - TestJob : Running subtask (3/3): FinalTask
           INFO -- FinalTask : Final processing of test_dir_item.rb
           INFO -- FinalTask : Final processing of test_file_item.rb
           INFO -- FinalTask : Final processing of test_work_item.rb
           WARN -- Run - TestJob : 1 subtask(s) halted in async process
           INFO -- Run - TestJob : Remote process failed
        STR

        check_status_log run.status_log, [
            { task: 'Run', status: :async_halt, progress: 3, max: 3 },
            { task: 'CollectFiles', status: :done, progress: 3, max: 3 },
            { task: 'ProcessingTask', status: :async_halt, progress: 3, max: 3 },
            { task: 'FinalTask', status: :done, progress: 3, max: 3 }
        ]

        check_status_log job.items.first.status_log, [
            { task: 'CollectFiles', status: :done },
            { task: 'ProcessingTask', status: :async_halt },
            { task: 'FinalTask', status: :done }
        ]
      end
    end

    context 'when stopped with fail' do
      let(:processing) { 'fail' }

      it 'should run final task' do
        run

        check_output logoutput, <<~STR
           INFO -- Run - TestJob : Ingest run started.
           INFO -- Run - TestJob : Running subtask (1/3): CollectFiles
           INFO -- Run - TestJob : Running subtask (2/3): ProcessingTask
          ERROR -- ProcessingTask - test_dir_item.rb : Task failed with failed status
          ERROR -- ProcessingTask - test_file_item.rb : Task failed with failed status
          ERROR -- ProcessingTask - test_work_item.rb : Task failed with failed status
          ERROR -- ProcessingTask - TestJob : 3 subitem(s) failed
           INFO -- Run - TestJob : Running subtask (3/3): FinalTask
           INFO -- FinalTask : Final processing of test_dir_item.rb
           INFO -- FinalTask : Final processing of test_file_item.rb
           INFO -- FinalTask : Final processing of test_work_item.rb
          ERROR -- Run - TestJob : 1 subtask(s) failed
           INFO -- Run - TestJob : Failed
        STR
        check_status_log run.status_log, [
            { task: 'Run', status: :failed, progress: 3, max: 3 },
            { task: 'CollectFiles', status: :done, progress: 3, max: 3 },
            { task: 'ProcessingTask', status: :failed, progress: 3, max: 3 },
            { task: 'FinalTask', status: :done, progress: 3, max: 3 }
        ]

        check_status_log job.items.first.status_log, [
            { task: 'CollectFiles', status: :done },
            { task: 'ProcessingTask', status: :failed },
            { task: 'FinalTask', status: :done }
        ]
      end

      it 'should run final task during retry' do
        run

        logoutput.truncate(0)
        run.execute :retry

        check_output logoutput, <<~STR
           INFO -- Run - TestJob : Ingest run started.
           INFO -- Run - TestJob : Running subtask (2/3): ProcessingTask
          ERROR -- ProcessingTask - test_dir_item.rb : Task failed with failed status
          ERROR -- ProcessingTask - test_file_item.rb : Task failed with failed status
          ERROR -- ProcessingTask - test_work_item.rb : Task failed with failed status
          ERROR -- ProcessingTask - TestJob : 3 subitem(s) failed
           INFO -- Run - TestJob : Running subtask (3/3): FinalTask
           INFO -- FinalTask : Final processing of test_dir_item.rb
           INFO -- FinalTask : Final processing of test_file_item.rb
           INFO -- FinalTask : Final processing of test_work_item.rb
          ERROR -- Run - TestJob : 1 subtask(s) failed
           INFO -- Run - TestJob : Failed
        STR

        check_status_log run.status_log, [
            { task: 'Run', status: :failed, progress: 3, max: 3 },
            { task: 'CollectFiles', status: :done, progress: 3, max: 3 },
            { task: 'ProcessingTask', status: :failed, progress: 3, max: 3 },
            { task: 'FinalTask', status: :done, progress: 3, max: 3 },
            { task: 'Run', status: :failed, progress: 3, max: 3 },
            { task: 'ProcessingTask', status: :failed, progress: 3, max: 3 },
            { task: 'FinalTask', status: :done, progress: 3, max: 3 }
        ]

        check_status_log job.items.first.status_log, [
            { task: 'CollectFiles', status: :done },
            { task: 'ProcessingTask', status: :failed },
            { task: 'FinalTask', status: :done },
            { task: 'ProcessingTask', status: :failed },
            { task: 'FinalTask', status: :done }
        ]
      end
    end

    context 'when stopped with error' do
      let(:processing) { 'error' }

      it 'should run final task' do
        run

        check_output logoutput, <<~STR
           INFO -- Run - TestJob : Ingest run started.
           INFO -- Run - TestJob : Running subtask (1/3): CollectFiles
           INFO -- Run - TestJob : Running subtask (2/3): ProcessingTask
          ERROR -- ProcessingTask - test_dir_item.rb : Error processing subitem (1/3): Task failed with WorkflowError exception
          ERROR -- ProcessingTask - test_file_item.rb : Error processing subitem (2/3): Task failed with WorkflowError exception
          ERROR -- ProcessingTask - test_work_item.rb : Error processing subitem (3/3): Task failed with WorkflowError exception
          ERROR -- ProcessingTask - TestJob : 3 subitem(s) failed
           INFO -- Run - TestJob : Running subtask (3/3): FinalTask
           INFO -- FinalTask : Final processing of test_dir_item.rb
           INFO -- FinalTask : Final processing of test_file_item.rb
           INFO -- FinalTask : Final processing of test_work_item.rb
          ERROR -- Run - TestJob : 1 subtask(s) failed
           INFO -- Run - TestJob : Failed
        STR

        check_status_log run.status_log, [
            { task: 'Run', status: :failed, progress: 3, max: 3 },
            { task: 'CollectFiles', status: :done, progress: 3, max: 3 },
            { task: 'ProcessingTask', status: :failed, progress: 0, max: 3 },
            { task: 'FinalTask', status: :done, progress: 3, max: 3 }
        ]

        check_status_log job.items.first.status_log, [
            { task: 'CollectFiles', status: :done },
            { task: 'ProcessingTask', status: :failed },
            { task: 'FinalTask', status: :done }
        ]
      end
    end

    context 'when stopped with abort' do
      let(:processing) { 'abort' }

      it 'should run final task' do
        run

        check_output logoutput, <<~STR
           INFO -- Run - TestJob : Ingest run started.
           INFO -- Run - TestJob : Running subtask (1/3): CollectFiles
           INFO -- Run - TestJob : Running subtask (2/3): ProcessingTask
          FATAL -- ProcessingTask - test_dir_item.rb : Fatal error processing subitem (1/3): Task failed with WorkflowAbort exception
          ERROR -- ProcessingTask - TestJob : 1 subitem(s) failed
           INFO -- Run - TestJob : Running subtask (3/3): FinalTask
           INFO -- FinalTask : Final processing of test_dir_item.rb
           INFO -- FinalTask : Final processing of test_file_item.rb
           INFO -- FinalTask : Final processing of test_work_item.rb
          ERROR -- Run - TestJob : 1 subtask(s) failed
           INFO -- Run - TestJob : Failed
        STR

        check_status_log run.status_log, [
            { task: 'Run', status: :failed, progress: 3, max: 3 },
            { task: 'CollectFiles', status: :done, progress: 3, max: 3 },
            { task: 'ProcessingTask', status: :failed, progress: 0, max: 3 },
            { task: 'FinalTask', status: :done, progress: 3, max: 3 }
        ]

        check_status_log job.items.first.status_log, [
            { task: 'CollectFiles', status: :done },
            { task: 'ProcessingTask', status: :failed },
            { task: 'FinalTask', status: :done }
        ]
      end
    end
  end
end
