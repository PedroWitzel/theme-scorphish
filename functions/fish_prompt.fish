# name: scorphish

# This file is part of theme-scorphish

# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
# Copyright (c) 2014, Pablo S. Blum de Aguiar <scorphus@gmail.com>

function _prompt_rust -a color -d "Display currently activated Rust"
  type -q rustc; or return
  [ "$theme_display_rust" != 'yes' ]; and return
  if echo $history[1] | grep -q 'rustup default'; or not set -q RUST_VERSION
    set -U RUST_VERSION (rustc --version | cut -d\  -f2)
  end
  echo -n -s "|" 🦀 $color $RUST_VERSION
end

function _prompt_whoami -a sep_color -a color -d "Display user@host if on a SSH session"
  if set -q SSH_TTY
    echo -n -s $color (whoami)@(hostname) $sep_color '|'
  end
end

function _git_dir
  echo (command git rev-parse --git-dir 2> /dev/null)
end

function _git_branch_name
  echo (command git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
end

function _git_tag_name
  echo (command git describe --tags --exact-match 2> /dev/null)
end

function _git_commit_sha1
  echo (command git rev-parse --short HEAD 2> /dev/null)
end

function _is_git_dirty
  if test "$theme_display_git_dirty" = no
    return 0
  end
  echo (command git status --short --ignore-submodules=all 2> /dev/null)
end

function _git_ahead_count -a remote -a branch_name
  echo (command git log $remote/$branch_name..HEAD 2> /dev/null | \
    grep '^commit' | wc -l | tr -d ' ')
end

function _git_read_file -a file_to_read
  echo (test -f "$file_to_read" && head -n 1 "$file_to_read" | string trim --right)
end

# Based on git's /mingw64/share/git/completion/git-prompt.sh
function _git_is_rebasing -a g red
  set -l r ""
  set -l b ""
  set -l step ""
  set -l total ""

  if test -d "$g/rebase-merge"
    set b (_git_read_file "$g/rebase-merge/head-name")
    set step (_git_read_file "$g/rebase-merge/msgnum")
    set total (_git_read_file "$g/rebase-merge/end")
    set r "REBASE"
  else if test -d "$g/rebase-apply"
    set step (_git_read_file "$g/rebase-apply/next")
    set total (_git_read_file "$g/rebase-apply/last")
    if test -f "$g/rebase-apply/rebasing"
      set b (_git_read_file "$g/rebase-apply/head-name")
      set r "REBASE"
    else if test -f "$g/rebase-apply/applying"
      set r "AM"
    else
      set r "AM/REBASE"
    end
  else if test -f "$g/REVERT_HEAD"
    set r "REVERTING"
  else if test -f "$g/CHERRY_PICK_HEAD"
    set r "CHERRY-PICKING"
  else if test -f "$g/MERGE_HEAD"
    set r "MERGING"
  else if test -f "$g/BISECT_LOG"
    set r "BISECTING"
  end

  if test -n "$r"
    if test -n "$b"
      set b (echo $b | string replace 'refs/heads/' '')
      echo -n -s $b $red " (" $r " " $step "/" $total ")"
    else
      echo -n -s $b $red " (" $r ")"
    end
  end
end

function _git_dirty_remotes -a remote_color -a ahead_color
  set current_branch (command git rev-parse --abbrev-ref HEAD 2> /dev/null)
  set current_ref (command git rev-parse HEAD 2> /dev/null)

  for remote in (git remote)

    set -l git_ahead_count (_git_ahead_count $remote $current_branch)

    set remote_branch "refs/remotes/$remote/$current_branch"
    set remote_ref (git for-each-ref --format='%(objectname)' $remote_branch)
    if test "$remote_ref" != ''
      if test "$remote_ref" != $current_ref
        if [ $git_ahead_count != 0 ]
          echo -n "$remote_color!"
          echo -n "$ahead_color+$git_ahead_count$normal"
        end
      end
    end
  end
end

function _prompt_versions -a blue gray green orange red append
  set -l prompt_rust (_prompt_rust $orange)
  echo -n -e -s "$prompt_rust"
end

function _prompt_git -a gray normal orange red yellow
  test "$theme_display_git" = no; and return

  set -l git_dir (_git_dir)
  test -z "$git_dir"; and return

  set -l git_reference (_git_is_rebasing $git_dir $red)

  if test -z $git_reference
    set -l git_branch (_git_branch_name)
    if test "$git_branch" = ''
      # Check for tag
      set git_tag (_git_tag_name)

      # if still empty, go for the commit SHA1
      if test "$git_tag" = ''
        set git_reference \( (_git_commit_sha1) \)
      else
        set git_reference \( $git_tag \)
      end
    else
      set git_reference $git_branch
    end
  end

  if [ (_is_git_dirty) ]
    echo -n -s $gray $yellow $git_reference $red '*' $gray ' '
  else
    echo -n -s $gray $yellow $git_reference $red $gray ' '
  end
end

function _prompt_pwd
  set_color -o cyan
  printf '%s' (prompt_pwd)
end

function _prompt_status_arrows -a exit_code
  if test $exit_code -ne 0
    set arrow_colors 600 900 c00 f00
  else
    set arrow_colors 060 090 0c0 0f0
  end

  for arrow_color in $arrow_colors
    set_color $arrow_color
    printf '»'
  end
end

function fish_prompt
  set -l exit_code $status

  set -l gray (set_color 666)
  set -l blue (set_color blue)
  set -l red (set_color red)
  set -l normal (set_color normal)
  set -l yellow (set_color yellow)
  set -l orange (set_color ff9900)
  set -l green (set_color green)

  printf '\n'$gray'['

  _prompt_whoami $gray $green

  if test "$theme_display_pwd_on_second_line" != yes
    _prompt_pwd
    printf '%s' $gray
  end

  _prompt_versions $blue $gray $green $orange $red

  printf '%s' $gray ']'

  if set -q theme_display_git_on_first_line
    printf ' '
    _prompt_git $gray $normal $orange $red $yellow
  end

  printf '⚡️ %0.3fs' (math $CMD_DURATION / 1000)

  printf '\n'
  if not set -q theme_display_git_on_first_line
    _prompt_git $gray $normal $orange $red $yellow
  end

  _prompt_status_arrows $exit_code
  printf ' '

  set_color normal
end
