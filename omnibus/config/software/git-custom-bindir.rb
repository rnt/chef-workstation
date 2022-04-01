#
# Copyright:: Copyright Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# NOTE - This is a straight copy of the git.rb definition in omnibus-software
# EXCEPT we specify a custom bindir when running make. We do this because
# we only want to include the Git binaries at the end of a user's path
# when they run `chef shell-init`. This is a temporary solution until we
# shave the yak of moving ruby into /opt/chefdk/bin and putting
# /opt/chefdk/embedded/bin at the end of the user's path.
# TODO - when deleting this, also delete omnibus/config/templates/git-custom-bindir

name "git-custom-bindir"
skip_transitive_dependency_licensing true

default_version "2.35.1"

license "LGPL-2.1"
license_file "LGPL-2.1"

dependency "curl"
dependency "zlib"
dependency "openssl"
dependency "pcre"
dependency "libiconv" # FIXME: can we figure out how to remove this?
dependency "expat"

relative_path "git-#{version}"

version("2.35.1") { source sha256: "9845a37dd01f9faaa7d8aa2078399d3aea91b43819a5efea6e2877b0af09bd43" }

source url: "https://www.kernel.org/pub/software/scm/git/git-#{version}.tar.gz"

bin_dirs ["#{install_dir}/gitbin", "#{install_dir}/embedded/libexec/git-core"]

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # We do a distclean so we ensure that the autoconf files are not trying to be
  # clever.
  make "distclean", env: env

  # Universal options
  config_hash = {
    NO_GETTEXT: "YesPlease",
    NEEDS_LIBICONV: "YesPlease",
    NO_INSTALL_HARDLINKS: "YesPlease",
    NO_PERL: "YesPlease",
    NO_PYTHON: "YesPlease",
    NO_TCLTK: "YesPlease",
    HAVE_PATHS_H: "YesPlease",
    NO_R_TO_GCC_LINKER: "YesPlease",
  }

  env["CFLAGS"] = "-I. #{env["CFLAGS"]}"
  env["CPPFLAGS"] = "-I. #{env["CPPFLAGS"]}"
  env["CXXFLAGS"] = "-I. #{env["CXXFLAGS"]}"
  env["CFLAGS"] = "-std=c99 #{env["CFLAGS"]}"

  erb source: "config.mak.erb",
      dest: "#{project_dir}/config.mak",
      mode: 0755,
      vars: {
               cc: env["CC"],
               ld: env["LD"],
               cflags: env["CFLAGS"],
               cppflags: env["CPPFLAGS"],
               install: env["INSTALL"],
               install_dir: install_dir,
               ldflags: env["LDFLAGS"],
               shell_path: env["SHELL_PATH"],
               config_hash: config_hash,
             }

  # NOTE - If you run ./configure the environment variables set above will not be
  # used and only the command line args will be used. The issue with this is you
  # cannot specify everything on the command line that you can with the env vars.
  make "prefix=#{install_dir}/embedded bindir=#{install_dir}/gitbin -j #{workers}", env: env
  make "prefix=#{install_dir}/embedded bindir=#{install_dir}/gitbin install", env: env
end
