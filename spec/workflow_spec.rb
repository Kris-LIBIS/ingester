# frozen_string_literal: true

require_relative 'spec_helper'

require 'stringio'
require 'awesome_print'
require 'active_support/core_ext/hash/reverse_merge'

basedir = File.absolute_path __dir__
datadir = File.join(basedir, 'data')

# noinspection RubyUnusedLocalVariable
def print_output(logoutput)
  # output = logoutput.string.lines.to_a.map { |x| x[/(?<=\] ).*?(?= @|$)/] }
  # puts 'output:'
  # puts output.join("\n")
end

def check_output(logoutput, sample_out)
  sample_out = sample_out.lines.to_a.map(&:strip)
  output = logoutput.string.lines.to_a.map { |x| x[/(?<=\] ).*?(?= @|$)/] }
  expect(output.size).to eq sample_out.size
  output.each_with_index do |o, i|
    expect(o.strip).to eq sample_out[i]
  end
end

# noinspection RubyUnusedLocalVariable
def print_status_log(status_log)
  # status_log = status_log.map(&:pretty)
  # puts 'status_log:'
  # puts(status_log.map do |log|
  #   "{task: '%<task>s', status: :%<status>s, progress: %<progress>d, max: %<max>d}" % log
  # end.join(",\n"))
end

def check_status_log(status_log, sample_status_log)
  status_log = status_log.map(&:pretty)
  expect(status_log.size).to eq sample_status_log.size
  sample_status_log.each_with_index do |h, i|
    h.keys.each do |key|
      # puts "key: #{key} : #{status_log[i][key]} <=> #{h[key]}"
      expect(status_log[i][key]).to eq h[key]
    end
  end
end

context 'Workflow' do

  let(:log_level) {:DEBUG}

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
        expect(tasks_info.size).to eq 4
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

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/4): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/4): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
          DEBUG -- PreProcess/ChecksumTester - IA1-1 : Processing subitem (1/1): abc
          DEBUG -- PreProcess/ChecksumTester - abc : Processing subitem (1/3): my_file_1.txt
          DEBUG -- PreProcess/ChecksumTester - abc : Processing subitem (2/3): my_file_2.txt
          DEBUG -- PreProcess/ChecksumTester - abc : Processing subitem (3/3): my_file_3.txt
          DEBUG -- PreProcess/ChecksumTester - abc : 3 of 3 subitems passed
          DEBUG -- PreProcess/ChecksumTester - IA1-1 : 1 of 1 subitems passed
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/4): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
          DEBUG -- PreIngest/CamelizeName - IA1-1 : Processing subitem (1/1): abc
          DEBUG -- PreIngest/CamelizeName - Abc : Processing subitem (1/3): my_file_1.txt
          DEBUG -- PreIngest/CamelizeName - Abc : Processing subitem (2/3): my_file_2.txt
          DEBUG -- PreIngest/CamelizeName - Abc : Processing subitem (3/3): my_file_3.txt
          DEBUG -- PreIngest/CamelizeName - Abc : 3 of 3 subitems passed
          DEBUG -- PreIngest/CamelizeName - IA1-1 : 1 of 1 subitems passed
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
          DEBUG -- PostIngest/ProcessingTask - IA1-1 : Processing subitem (1/1): Abc
          DEBUG -- PostIngest/ProcessingTask - Abc : Processing subitem (1/3): MyFile1.txt
           INFO -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task success
          DEBUG -- PostIngest/ProcessingTask - Abc : Processing subitem (2/3): MyFile2.txt
           INFO -- PostIngest/ProcessingTask - Abc/MyFile2.txt : Task success
          DEBUG -- PostIngest/ProcessingTask - Abc : Processing subitem (3/3): MyFile3.txt
           INFO -- PostIngest/ProcessingTask - Abc/MyFile3.txt : Task success
          DEBUG -- PostIngest/ProcessingTask - Abc : 3 of 3 subitems passed
          DEBUG -- PostIngest/ProcessingTask - IA1-1 : 1 of 1 subitems passed
           INFO -- PostIngest - IA1-1 : Running subtask (2/2): FinalTask
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
            {task: 'Run', status: :done, progress: 4, max: 4},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'PostIngest', status: :done, progress: 2, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :done, progress: 1, max: 1},
            {task: 'PostIngest/FinalTask', status: :done, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            { task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3 },
            { task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3 },
            { task: 'PostIngest/ProcessingTask', status: :done, progress: 3, max: 3 },
            { task: 'PostIngest/FinalTask', status: :done, progress: 3, max: 3 }
        ]

        check_status_log job.items.first.items.first.status_log, [
            { task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0 },
            { task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0 },
            { task: 'PostIngest/ProcessingTask', status: :done, progress: 0, max: 0 },
            { task: 'PostIngest/FinalTask', status: :done, progress: 0, max: 0 }
        ]
      end
    end

    context 'when stopped with async_halt' do
      let(:processing) { 'async_halt' }
      let(:log_level) {:INFO}

      it 'should not run final task' do
        run

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/4): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/4): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/4): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task failed with async_halt status
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile2.txt : Task failed with async_halt status
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile3.txt : Task failed with async_halt status
           WARN -- PostIngest/ProcessingTask - Abc : 3 subitem(s) halted in async process
           WARN -- PostIngest/ProcessingTask - IA1-1 : 1 subitem(s) halted in async process
           WARN -- PostIngest - IA1-1 : 1 subtask(s) halted in async process
           INFO -- PostIngest - IA1-1 : Remote process failed
           WARN -- Run - IA1-1 : 1 subtask(s) halted in async process
           INFO -- Run - IA1-1 : Remote process failed
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :async_halt, progress: 4, max: 4},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'PostIngest', status: :async_halt, progress: 1, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :async_halt, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :async_halt, progress: 3, max: 3}
        ]

        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :async_halt, progress: 0, max: 0}
        ]
      end
    end

    context 'when stopped with fail' do
      let(:processing) { 'fail' }
      let(:log_level) { :INFO }

      it 'should not run final task' do
        run

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/4): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/4): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/4): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task failed with failed status
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile2.txt : Task failed with failed status
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile3.txt : Task failed with failed status
          ERROR -- PostIngest/ProcessingTask - Abc : 3 subitem(s) failed
          ERROR -- PostIngest/ProcessingTask - IA1-1 : 1 subitem(s) failed
          ERROR -- PostIngest - IA1-1 : 1 subtask(s) failed
           INFO -- PostIngest - IA1-1 : Failed
          ERROR -- Run - IA1-1 : 1 subtask(s) failed
           INFO -- Run - IA1-1 : Failed
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :failed, progress: 4, max: 4},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'PostIngest', status: :failed, progress: 1, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 3, max: 3}
        ]

        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 0, max: 0}
        ]
      end
    end

    context 'when stopped with error' do
      let(:processing) { 'error' }
      let(:log_level) { :INFO }

      it 'should not run final task' do
        run

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/4): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/4): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/4): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc : Error processing subitem (1/3): Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile2.txt : Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc : Error processing subitem (2/3): Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile3.txt : Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc : Error processing subitem (3/3): Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc : 3 subitem(s) failed
          ERROR -- PostIngest/ProcessingTask - IA1-1 : 1 subitem(s) failed
          ERROR -- PostIngest - IA1-1 : 1 subtask(s) failed
           INFO -- PostIngest - IA1-1 : Failed
          ERROR -- Run - IA1-1 : 1 subtask(s) failed
           INFO -- Run - IA1-1 : Failed
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :failed, progress: 4, max: 4},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'PostIngest', status: :failed, progress: 1, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 1, max: 1}
        ]
        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 3, max: 3}
        ]
        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 0, max: 0}
        ]
      end
    end

    context 'when stopped with abort' do
      let(:processing) { 'abort' }
      let(:log_level) { :INFO }

      it 'should not run final task' do
        run

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/4): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/4): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/4): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task failed with WorkflowAbort exception
          FATAL -- PostIngest/ProcessingTask - Abc : Fatal error processing subitem (1/3): Task failed with WorkflowAbort exception
          ERROR -- PostIngest/ProcessingTask - Abc : 1 subitem(s) failed
          ERROR -- PostIngest/ProcessingTask - IA1-1 : 1 subitem(s) failed
          ERROR -- PostIngest - IA1-1 : 1 subtask(s) failed
           INFO -- PostIngest - IA1-1 : Failed
          ERROR -- Run - IA1-1 : 1 subtask(s) failed
           INFO -- Run - IA1-1 : Failed
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :failed, progress: 4, max: 4},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'PostIngest', status: :failed, progress: 1, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 1, max: 3}
        ]

        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 0, max: 0}
        ]
      end
    end
  end

  context 'with forcing final task' do
    let(:force_run) { true }
    let(:log_level) { :INFO }

    context 'when processing successfully' do
      let(:processing) { 'success' }

      it 'should run final task' do
        run

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/4): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/4): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/4): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
           INFO -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task success
           INFO -- PostIngest/ProcessingTask - Abc/MyFile2.txt : Task success
           INFO -- PostIngest/ProcessingTask - Abc/MyFile3.txt : Task success
           INFO -- PostIngest - IA1-1 : Running subtask (2/2): FinalTask
           INFO -- PostIngest/FinalTask : Final processing of MyFile1.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile2.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile3.txt
           INFO -- PostIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Done
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :done, progress: 4, max: 4},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'PostIngest', status: :done, progress: 2, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :done, progress: 1, max: 1},
            {task: 'PostIngest/FinalTask', status: :done, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/FinalTask', status: :done, progress: 3, max: 3}
        ]

        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/FinalTask', status: :done, progress: 0, max: 0}
        ]
      end
    end

    context 'when stopped with async_halt' do
      let(:processing) { 'async_halt' }

      it 'should run final task' do
        run

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/4): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/4): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/4): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task failed with async_halt status
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile2.txt : Task failed with async_halt status
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile3.txt : Task failed with async_halt status
           WARN -- PostIngest/ProcessingTask - Abc : 3 subitem(s) halted in async process
           WARN -- PostIngest/ProcessingTask - IA1-1 : 1 subitem(s) halted in async process
           INFO -- PostIngest - IA1-1 : Running subtask (2/2): FinalTask
           INFO -- PostIngest/FinalTask : Final processing of MyFile1.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile2.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile3.txt
           WARN -- PostIngest - IA1-1 : 1 subtask(s) halted in async process
           INFO -- PostIngest - IA1-1 : Remote process failed
           WARN -- Run - IA1-1 : 1 subtask(s) halted in async process
           INFO -- Run - IA1-1 : Remote process failed
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :async_halt, progress: 4, max: 4},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'PostIngest', status: :async_halt, progress: 2, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :async_halt, progress: 1, max: 1},
            {task: 'PostIngest/FinalTask', status: :done, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :async_halt, progress: 3, max: 3},
            {task: 'PostIngest/FinalTask', status: :done, progress: 3, max: 3}
        ]

        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :async_halt, progress: 0, max: 0},
            {task: 'PostIngest/FinalTask', status: :done, progress: 0, max: 0}
        ]
      end
    end

    context 'when stopped with fail' do
      let(:processing) { 'fail' }
      let(:debug_level) { :DEBUG }

      it 'should run final task' do
        run

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/4): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/4): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/4): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task failed with failed status
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile2.txt : Task failed with failed status
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile3.txt : Task failed with failed status
          ERROR -- PostIngest/ProcessingTask - Abc : 3 subitem(s) failed
          ERROR -- PostIngest/ProcessingTask - IA1-1 : 1 subitem(s) failed
           INFO -- PostIngest - IA1-1 : Running subtask (2/2): FinalTask
           INFO -- PostIngest/FinalTask : Final processing of MyFile1.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile2.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile3.txt
          ERROR -- PostIngest - IA1-1 : 1 subtask(s) failed
           INFO -- PostIngest - IA1-1 : Failed
          ERROR -- Run - IA1-1 : 1 subtask(s) failed
           INFO -- Run - IA1-1 : Failed
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :failed, progress: 4, max: 4},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'PostIngest', status: :failed, progress: 2, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 1, max: 1},
            {task: 'PostIngest/FinalTask', status: :done, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 3, max: 3},
            {task: 'PostIngest/FinalTask', status: :done, progress: 3, max: 3}
        ]

        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 0, max: 0},
            {task: 'PostIngest/FinalTask', status: :done, progress: 0, max: 0}
        ]
      end

      it 'should run final task during retry' do
        run

        logoutput.truncate(0)
        run = job.execute action: 'retry'

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        expect(job.items.size).to eql 1
        expect(job.items.first.size).to eql 3

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task failed with failed status
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile2.txt : Task failed with failed status
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile3.txt : Task failed with failed status
          ERROR -- PostIngest/ProcessingTask - Abc : 3 subitem(s) failed
          ERROR -- PostIngest/ProcessingTask - IA1-1 : 1 subitem(s) failed
           INFO -- PostIngest - IA1-1 : Running subtask (2/2): FinalTask
           INFO -- PostIngest/FinalTask : Final processing of MyFile1.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile2.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile3.txt
          ERROR -- PostIngest - IA1-1 : 1 subtask(s) failed
           INFO -- PostIngest - IA1-1 : Failed
          ERROR -- Run - IA1-1 : 1 subtask(s) failed
           INFO -- Run - IA1-1 : Failed
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :failed, progress: 4, max: 4},
            {task: 'PostIngest', status: :failed, progress: 2, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 1, max: 1},
            {task: 'PostIngest/FinalTask', status: :done, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 3, max: 3},
            {task: 'PostIngest/FinalTask', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 3, max: 3},
            {task: 'PostIngest/FinalTask', status: :done, progress: 3, max: 3}
        ]

        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 0, max: 0},
            {task: 'PostIngest/FinalTask', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 0, max: 0},
            {task: 'PostIngest/FinalTask', status: :done, progress: 0, max: 0}
        ]
      end
    end

    context 'when stopped with error' do
      let(:processing) { 'error' }

      it 'should run final task' do
        run

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/4): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/4): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/4): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc : Error processing subitem (1/3): Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile2.txt : Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc : Error processing subitem (2/3): Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile3.txt : Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc : Error processing subitem (3/3): Task failed with WorkflowError exception
          ERROR -- PostIngest/ProcessingTask - Abc : 3 subitem(s) failed
          ERROR -- PostIngest/ProcessingTask - IA1-1 : 1 subitem(s) failed
           INFO -- PostIngest - IA1-1 : Running subtask (2/2): FinalTask
           INFO -- PostIngest/FinalTask : Final processing of MyFile1.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile2.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile3.txt
          ERROR -- PostIngest - IA1-1 : 1 subtask(s) failed
           INFO -- PostIngest - IA1-1 : Failed
          ERROR -- Run - IA1-1 : 1 subtask(s) failed
           INFO -- Run - IA1-1 : Failed
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :failed, progress: 4, max: 4},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'PostIngest', status: :failed, progress: 2, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 1, max: 1},
            {task: 'PostIngest/FinalTask', status: :done, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 3, max: 3},
            {task: 'PostIngest/FinalTask', status: :done, progress: 3, max: 3}
        ]

        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 0, max: 0},
            {task: 'PostIngest/FinalTask', status: :done, progress: 0, max: 0}
        ]
      end
    end

    context 'when stopped with abort' do
      let(:processing) { 'abort' }

      it 'should run final task' do
        run

        print_output(logoutput)
        print_status_log(run.status_log)
        print_status_log(job.items.first.status_log)
        print_status_log(job.items.first.items.first.status_log)

        check_output logoutput, <<~STR
           INFO -- Run - IA1-1 : Ingest run started.
           INFO -- Run - IA1-1 : Running subtask (1/4): Collect
           INFO -- Collect - IA1-1 : Running subtask (1/1): CollectFiles
           INFO -- Collect - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (2/4): PreProcess
           INFO -- PreProcess - IA1-1 : Running subtask (1/1): ChecksumTester
           INFO -- PreProcess - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (3/4): PreIngest
           INFO -- PreIngest - IA1-1 : Running subtask (1/1): CamelizeName
           INFO -- PreIngest - IA1-1 : Done
           INFO -- Run - IA1-1 : Running subtask (4/4): PostIngest
           INFO -- PostIngest - IA1-1 : Running subtask (1/2): ProcessingTask
          ERROR -- PostIngest/ProcessingTask - Abc/MyFile1.txt : Task failed with WorkflowAbort exception
          FATAL -- PostIngest/ProcessingTask - Abc : Fatal error processing subitem (1/3): Task failed with WorkflowAbort exception
          ERROR -- PostIngest/ProcessingTask - Abc : 1 subitem(s) failed
          ERROR -- PostIngest/ProcessingTask - IA1-1 : 1 subitem(s) failed
           INFO -- PostIngest - IA1-1 : Running subtask (2/2): FinalTask
           INFO -- PostIngest/FinalTask : Final processing of MyFile1.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile2.txt
           INFO -- PostIngest/FinalTask : Final processing of MyFile3.txt
          ERROR -- PostIngest - IA1-1 : 1 subtask(s) failed
           INFO -- PostIngest - IA1-1 : Failed
          ERROR -- Run - IA1-1 : 1 subtask(s) failed
           INFO -- Run - IA1-1 : Failed
        STR

        check_status_log run.status_log, [
            {task: 'Run', status: :failed, progress: 4, max: 4},
            {task: 'Collect', status: :done, progress: 1, max: 1},
            {task: 'Collect/CollectFiles', status: :done, progress: 0, max: 0},
            {task: 'PreProcess', status: :done, progress: 1, max: 1},
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 1, max: 1},
            {task: 'PreIngest', status: :done, progress: 1, max: 1},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 1, max: 1},
            {task: 'PostIngest', status: :failed, progress: 2, max: 2},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 1, max: 1},
            {task: 'PostIngest/FinalTask', status: :done, progress: 1, max: 1}
        ]

        check_status_log job.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 3, max: 3},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 3, max: 3},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 1, max: 3},
            {task: 'PostIngest/FinalTask', status: :done, progress: 3, max: 3}
        ]

        check_status_log job.items.first.items.first.status_log, [
            {task: 'PreProcess/ChecksumTester', status: :done, progress: 0, max: 0},
            {task: 'PreIngest/CamelizeName', status: :done, progress: 0, max: 0},
            {task: 'PostIngest/ProcessingTask', status: :failed, progress: 0, max: 0},
            {task: 'PostIngest/FinalTask', status: :done, progress: 0, max: 0}
        ]
      end
    end
  end
end
