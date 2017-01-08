#!/bin/bash

fmt='  %-20s => %-s\n'
var='some teXT'
abc='abcdefghi'
mirror='abcABC123ABCabc'
empty=''
x=3
y=2
pat='B*c'

printf '\n%s\n' "[String Length]"
printf "${fmt}" '${var}'    "${var}"     # Normal value for $var
printf "${fmt}" '${#var}'   "${#var}"    # Length for var
printf "${fmt}" '${empty}'  "${empty}"   # Normal value for $var
printf "${fmt}" '${#empty}' "${#empty}"  # Length for var

printf '\n%s\n' "[Case Conversion]"
printf "${fmt}" '${var}'          "${var}"           # Normal value for $var
printf "${fmt}" '${var~}'         "${var~}"          # Upper case first
printf "${fmt}" '${var~~}'        "${var~~}"         # Transpose Case
printf "${fmt}" '${var,}'         "${var,}"          # Lower case first
printf "${fmt}" '${var,,}'        "${var,,}"         # Lower case all
printf "${fmt}" '${var^}'         "${var^}"          # Upper case first
printf "${fmt}" '${var^^}'        "${var^^}"         # Upper case all
printf "${fmt}" '${var^^[aeiou]}' "${var^^[aeiou]}"  # Upper case all that regex match [aeiou]
printf "${fmt}" '${var,,[XYZ]}'   "${var,,[XYZ]}"    # Lower case all that regex match [XYZ]
printf "${fmt}" '${var~~[aeiou]}' "${var~~[aeiou]}"  # Transpose all that regex match [aeiou]

printf '\n%s\n' "[Default Values]"
printf '  %s\n' '-- Normal values'
printf "${fmt}" '${var}'           "${var}"            # Normal value for $var
printf "${fmt}" '${empty}'         "${empty}"          # Normal value for $empty
printf "${fmt}" '${fake}'          "${fake}"           # Fake variable (it's un-set)
printf '  %s\n' '-- Show "hi" if variable is empty'
printf "${fmt}" '${var:-hi}'       "${var:-hi}"        # $var not empty, so default not used
printf "${fmt}" '${empty:-hi}'     "${empty:-hi}"      # $empty is empty, so default is used
printf "${fmt}" '${fake:-hi}'      "${fake:-hi}"       # $fake is empty/unset, so default used
printf '  %s\n' '-- Show "not set" if variable is unset'
printf "${fmt}" '${var-not set}'   "${var-not set}"    # $var exists, so prints normally.
printf "${fmt}" '${empty-not set}' "${empty-not set}"  # $empty exists, so prints normally.
printf "${fmt}" '${fake-not set}'  "${fake-not set}"   # $fake isn't set, so prints 'not set'
printf '  %s\n' '-- Show "is set" if variable is set'
printf "${fmt}" '${var+is set}'    "${var+is set}"     # $var exists, so print 'is set'
printf "${fmt}" '${empty+is set}'  "${empty+is set}"   # $empty exists, so print 'is set'
printf "${fmt}" '${fake+is set}'   "${fake+is set}"    # $fake isn't set, so print nothing
printf '  %s\n' '-- Assign "hello" if variable is unset, then show'
printf "${fmt}" '${var=hello}'     "${var=hello}"     # $var exists, so print 'is set'
printf "${fmt}" '${empty=hello}'   "${empty=hello}"   # $empty exists, so print 'is set'
printf "${fmt}" '${fake=hello}'    "${fake=hello}"    # $fake isn't set, so print nothing
unset fake
printf '  %s\n' '-- Assign "hello" if variable is unset or blank, then show'
printf "${fmt}" '${var:=hello}'    "${var:=hello}"    # $var exists, so print 'is set'
printf "${fmt}" '${empty:=hello}'  "${empty:=hello}"  # $empty exists, so print 'is set'
printf "${fmt}" '${fake:=hello}'   "${fake:=hello}"   # $fake isn't set, so print nothing

printf '\n%s\n' "[Substrings (positional)]"        # 0-based index!
printf "${fmt}" 'Positive Index' '012345678'       # Show the indexes.
printf "${fmt}" 'Negative Index' '987654321'       # Show the negative indexes
printf "${fmt}" '$x and $y are'  "${x}, ${y}"      # Normal values for $x and $y
printf "${fmt}" '${abc}'         "${abc}"          # Normal value for $abc
printf "${fmt}" '${abc: 1}'      "${abc: 1}"       # Index 1, to-end
printf "${fmt}" '${abc: 1: 3}'   "${abc: 1: 3}"    # Index 1, length 3
printf "${fmt}" '${abc: 1: -3}'  "${abc: 1: -3}"   # Index 1, to negative index 3
printf "${fmt}" '${abc: -3}'     "${abc: -3}"      # Negative index 3, to-end
printf "${fmt}" '${abc: -3: 2}'  "${abc: -3: 2}"   # Negative index 3, length 2
printf "${fmt}" '${abc: -3: -2}' "${abc: -3: -2}"  # Negative index 3, to negative index 2
printf "${fmt}" '${abc: $x: $y}' "${abc: $x: $y}"  # Using variables inside braces

printf '\n%s\n' '[Substrings (pattern replacement)]'       #
printf "${fmt}" '${mirror}'         "${mirror}"            # Normal value for $mirror
printf "${fmt}" '${mirror/abc/xyz}' "${mirror/abc/xyz}"    # Replace first abc with xyz
printf "${fmt}" '${mirror//abc/xyz}' "${mirror//abc/xyz}"  # Replace all abc with xyz
printf "${fmt}" '${mirror/#abc/xyz}' "${mirror/#abc/xyz}"  # Replace front abc with xyz
printf "${fmt}" '${mirror/%abc/xyz}' "${mirror/%abc/xyz}"  # Replace last abc with xyz

printf '\n%s\n' '[Substrings (pattern-deletion)]'  #
printf "${fmt}" '$pat is'        "${pat}"          # Normal values for $x and $y
printf "${fmt}" '${mirror}'      "${mirror}"       # Normal value for $mirror
printf "${fmt}" '${mirror#a*C}'  "${mirror#a*C}"   # Erase shortest match from front of string
printf "${fmt}" '${mirror##a*C}' "${mirror##a*C}"  # Erase longest match from front of string
                                                   #   abcABC123ABCabc
                                                   #   ^----^           shortest a*C (glob)
                                                   #   ^----------^     longest  a*C (glob)
printf "${fmt}" '${mirror%B*c}'  "${mirror%B*c}"   # Erase shortest match from back of string
printf "${fmt}" '${mirror%%B*c}' "${mirror%%B*c}"  # Erase longest match from back of string
                                                   #   abcABC123ABCabc
                                                   #             ^---^  shortest B*c (glob)
                                                   #       ^---------^  longest  B*c (glob)
printf "${fmt}" '${mirror//abc}' "${mirror//abc}"  # Erase all abc
printf "${fmt}" '${mirror#$pat}' "${mirror#$pat}"  # Variables work inside braces :)


printf '\n%s\n' '[Positionals ($@ and $*)]'
printf "${fmt}" 'Special rules!' 'Different video.'

# More examples at: http://www.tldp.org/LDP/abs/html/string-manipulation.html
