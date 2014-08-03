# Use hiera with puppet facts, see tools/bootstrap

node default {
  hiera_include("classes.${infra_role}")
}
