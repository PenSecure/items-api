module "ecr" {
  source = "../../modules/ecr"

  name               = var.project
  keep_tagged_images = var.keep_tagged_images
}

module "ci_role" {
  source = "../../modules/github-oidc-role"

  role_name            = "${var.project}-${var.environment}-github-ci"
  github_repository    = var.github_repository
  create_oidc_provider = var.create_oidc_provider
  ecr_repository_arns  = [module.ecr.repository_arn]
}
