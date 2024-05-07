KManager.action :bootstrap do
  action do
    application_name = 'appydave-tools'

    # Ruby Gem Bootstrap
    director = KDirector::Dsls::RubyGemDsl
      .init(k_builder,
        on_exist:                   :skip,                      # %i[skip write compare]
        on_action:                  :queue                      # %i[queue execute]
      )
      .data(
        ruby_version:               '2.7',
        application:                application_name,
        application_description:    'AppyDave YouTube Automation Tools',
        application_lib_path:       application_name.to_s, # need a specialized handlebars helper to turn this into a path, e.g ps-common => ps/common
        application_lib_namespace:  'Appydave::Tools',
        namespaces:                 ['Appydave', 'Tools'],
        author:                     'David Cruwys',
        author_email:               'david@ideasmen.com.au',
        initial_semver:             '0.0.1',
        main_story:                 'As a Content Creator, I want accellerate my video creation, so that I can improve speed and quality of my content',
        copyright_date:             '2024',
        website:                    'http://appydave.com/gems/appydave-tools'
      )
      .github(
        active: false,
        repo_name: application_name
      ) do
        create_repository
        # delete_repository
        # list_repositories
        open_repository
        # run_command('git init')
      end
      .blueprint(
        active: false,
        name: :bin_hook,
        description: 'initialize repository',
        on_exist: :write) do

        cd(:app)

        run_template_script('bin/runonce/git-setup.sh', dom: dom)

        add('.githooks/commit-msg').run_command('chmod +x .githooks/commit-msg')
        add('.githooks/pre-commit').run_command('chmod +x .githooks/pre-commit')

        add('.gitignore')

        run_command('git config core.hooksPath .githooks') # enable sharable githooks (developer needs to turn this on before editing rep)

        run_command("git add .; git commit -m 'chore: #{self.options.description.downcase}'; git push")
        run_command("gh repo edit -d \"#{dom[:application_description]}\"")
      end
      .package_json(
        active: true,
        name: :package_json,
        description: 'Set up the package.json file for semantic versioning'
      ) do
        self
          .add('package.json', dom: dom)
          .play_actions

        self
          .add_script('release', 'semantic-release')
          .sort
          .development
          .npm_add_group('semver-ruby')

        run_command("git add .; git commit -m 'chore: #{self.options.description.downcase}'; git push")
      end
      .blueprint(
        active: false,
        name: :opinionated,
        description: 'opinionated GEM files',
        on_exist: :write) do

        cd(:app)

        add('bin/setup')
        add('bin/console')

        applet_path = typed_dom.namespaces.map { |ns| ns.downcase }.join('/')
        
        add("lib/#{applet_path}.rb"               , template_file: 'lib/applet_name.rb'         , dom: dom)
        add("lib/#{applet_path}/version.rb"       , template_file: 'lib/applet_name/version.rb' , dom: dom)
    
        add('spec/spec_helper.rb')
        add("spec/#{applet_path}_spec.rb"         , template_file: 'spec/applet_name_spec.rb', dom: dom)

        add("#{typed_dom.application}.gemspec"    , template_file: 'applet_name.gemspec', dom: dom)
        add('Gemfile', dom: dom)
        add('Guardfile', dom: dom)
        add('Rakefile', dom: dom)
        add('.rspec', dom: dom)
        add('.rubocop.yml', dom: dom)
        add('README.md', dom: dom)
        add('CODE_OF_CONDUCT.md', dom: dom)
        add('LICENSE.txt', dom: dom)

        run_command("rubocop -a")
      
        run_command("git add .; git commit -m 'chore: #{self.options.description.downcase}'; git push")
      end
      .blueprint(
        active: false,
        name: :ci_cd,
        description: 'github actions (CI/CD)',
        on_exist: :write) do

        cd(:app)

        # run_command("gh secret set SLACK_WEBHOOK --body \"$SLACK_REPO_WEBHOOK\"")
        run_command("gh secret set GEM_HOST_API_KEY --body \"$GEM_HOST_API_KEY\"")

        add('.github/workflows/main.yml')
        add('.releaserc.json')

        run_command("git add .; git commit -m 'chore: #{self.options.description.downcase}'; git push")
      end

    director.play_actions
    # director.builder.logit
  end
end

KManager.opts.app_name                    = 'appydave-tools'
KManager.opts.sleep                       = 2
KManager.opts.reboot_on_kill              = 0
KManager.opts.reboot_sleep                = 4
KManager.opts.exception_style             = :short
KManager.opts.show.time_taken             = true
KManager.opts.show.finished               = true
KManager.opts.show.finished_message       = 'FINISHED :)'
