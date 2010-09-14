# richard_gill

Simple Versioning for DataMapper Models

[richard_gill](http://github.com/okbreathe/richard_gill) tracks changes
of your objects over time by storing serialized hashes of changesets.

This can be used to implement version control (by traversing up the changeset
chain) or to create a log of activity.

## Usage

### Watch `SomeModel`:

    class SomeModel
      is :watched

See `is_watched` in `richard_gill.rb` for options.

### Working with versions

    # Revert an object to a previous version
    @some_object.revert

    # Revert an object to two versions prior
    @some_object.revert(2) 

    # Show all object versions
    @some_object.versions

Note that calling `revert` does not make any changes to the object, and you must #save
the object after calling revert. To do this in one step use `object.revert!`.

## Storing the user with the changeset

It's nice to know WHO made the changes on the object. By default, RichardGill
stores this as `updated_by`. This can be explicitly set when saving a version or ...
instead of passing around the user, create a User::current method!

    class User
      class << self
        def current
          Thread.current[:user]
        end

        def current=(user)
          raise(ArgumentError,
            "Invalid user. Expected an object of class 'User', got #{user.inspect}") unless user.is_a?(User)
          Thread.current[:user] = user
        end
      end
    end

If Richard Gill sees that the "User" class responds to a #current method, it will use that instead of requiring
an explicit updated_by to be passed in during object updates.

## Erata

Named for the character of Special Agent Richard Gill from the best movie to ever grace the silver screen, Hackers.

"I'm watching yoooou." - Special Agent Richard Gill

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Asher Van Brunt. See LICENSE for details.
