if(interactive()) library(testthat)

pkg_root <- make_pkg_root()
create_package_vault(pkg_root)

{
  alice <- "alice"
  bob   <- "bob"
  user_keys_dir <- file.path(system.file(package = "secret"), "user_keys")
  key <- function(x)file.path(user_keys_dir, x)
  alice_public_key  <- key("alice.pub")
  alice_private_key <- key("alice.pem")
  bob_public_key    <- key("bob.pub")
  bob_private_key   <- key("bob.pem")
  carl_private_key   <- key("carl.pem")
}


context("secrets")

secret_to_keep <- list(a = 1, b = letters)


test_that("can add secrets", {
  
  add_user(alice, alice_public_key, vault = pkg_root)
  
  expect_null(
    add_secret("secret_one", secret_to_keep, users = alice, vault = pkg_root)
  )
  
  expect_error(
    add_secret("secret_one", secret_to_keep, users = alice, vault = pkg_root),
    "Secret name already exists"
  )
  
  expect_equal(
    list_secrets(pkg_root),
    "secret_one"
  )
})


test_that("alice can decrypt secret", {
  # Error on public key
  expect_error(
    get_secret("secret_one", key = alice_public_key, vault = pkg_root),
    "Access denied to secret"
  )
  # Success on private key
  expect_equal(
    get_secret("secret_one", key = alice_private_key, vault = pkg_root),
    secret_to_keep
  )
})


test_that("bob can not decrypt secret", {
  expect_error(
    get_secret("secret_one", key = bob_public_key, vault = pkg_root),
    "Access denied to secret"
  )
  expect_error(
    get_secret("secret_one", key = bob_private_key, vault = pkg_root),
    "Access denied to secret"
  )
})


test_that("add second secret shared by multiple users", {
  expect_equal(
    basename(
      add_user(bob, bob_public_key, vault = pkg_root)
    ),
    "bob.pem"
  )
  expect_null(
    add_secret("secret_two", iris, users = c(alice, bob), vault = pkg_root)
  )
  expect_equal(
    list_secrets(pkg_root),
    c("secret_one", "secret_two")
  )
  expect_error(
    # alice can not decrypt with public key
    get_secret("secret_two", key = alice_public_key, vault = pkg_root)
  )
  expect_equal(
    # alice can decrypt with private key
    get_secret("secret_two", key = alice_private_key, vault = pkg_root),
    iris
  )
  
  expect_error(
    # bob can not decrypt with public key
    get_secret("secret_two", key = bob_public_key, vault = pkg_root)
  )
  expect_equal(
    # bob can decrypt with private key
    get_secret("secret_two", key = bob_private_key, vault = pkg_root),
    iris
  )
  expect_error(
    # carl can not decrypt with private key
    get_secret("secret_two", key = carl_private_key, vault = pkg_root)
  )
  
  # delete user and try to access secret
  expect_null(
    delete_user(alice, vault = pkg_root)
  )
  
  # User 1 should not be able to access the secret
  expect_error(
    get_secret("secret_two", key = alice_private_key, vault = pkg_root),
    "Access denied to secret"
  )
  
  # user 2 should still see the secret
  expect_equal(
    get_secret("secret_two", key = bob_private_key, vault = pkg_root),
    iris
  )
  
  
  expect_null(
    delete_secret("secret_two", vault = pkg_root)
  )
  
  expect_equal(
    list_secrets(pkg_root),
    "secret_one"
  )
  expect_equal(
    list_users(pkg_root),
    "bob"
  )
})


# share-secret --------------------------------------------------------

test_that("use share_secret() to share between alice and bob", {
  add_user(alice, alice_public_key, vault = pkg_root)
  expect_null(
    add_secret("secret_3", mtcars, users = c(alice), vault = pkg_root)
  )
  expect_equal(
    list_secrets(pkg_root),
    c("secret_3", "secret_one")
  )
  
  expect_null(
    share_secret("secret_3", users = c(alice, bob), 
                 key = alice_private_key, vault = pkg_root)
  )
  
  expect_equal(
    # alice can decrypt with private key
    get_secret("secret_3", key = alice_private_key, vault = pkg_root),
    mtcars
  )
  
  expect_equal(
    # bob can decrypt with private key
    get_secret("secret_3", key = bob_private_key, vault = pkg_root),
    mtcars
  )

  expect_equal(
    list_secrets(pkg_root),
    c("secret_3", "secret_one")
  )
  expect_equal(
    list_users(pkg_root),
    c("alice", "bob")
  )
})


test_that("unshare a secret", {
  expect_null(
  unshare_secret("secret_3", users = bob, vault = pkg_root)
  )
  expect_error(
    # bob can no longer decrypt with private key
    get_secret("secret_3", key = bob_private_key, vault = pkg_root)
  )
})

test_that("udpate a secret", {
  expect_equal(
    get_secret("secret_3", key = alice_private_key, vault = pkg_root),
    mtcars
  )
  expect_null(
  update_secret("secret_3", value = "foo", key = alice_private_key, 
                vault = pkg_root)
  )
  expect_equal(
    get_secret("secret_3", key = alice_private_key, vault = pkg_root),
    "foo"
  )
  
})