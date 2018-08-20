context("Addition")

test_that("Addition works", {
  expect_equal(add(1), 2)
  expect_equal(add(2), 3)
  expect_equal(add(3,4) , 7)
})
