#' @rdname credentials
#' @title Locate AWS Credentials
#' @description Locate AWS credentials from likely sources
#' @param key An AWS Access Key ID
#' @param secret An AWS Secret Access Key
#' @param session_token Optionally, an AWS Security Token Service (STS) temporary Session Token
#' @param region A character string containing the AWS region for the request. If missing, \dQuote{us-east-1} is assumed.
#' @param file A character string containing a path to a \samp{.aws/credentials} file.
#' @param profile A character string specifying which profile to use from the file. By default, the \dQuote{default} profile is used.
#' @param default_region A character string specifying a default string to use of no user-supplied value is found.
#' @param verbose A logical indicating whether to be verbose.
#' @details These functions locate values of AWS credentials (access key, secret access key, session token, and region) from likely sources. The order in which these are searched is as follows:
#' \enumerate{
#'   \item values passed to the function
#'   \item environment variables (\env{AWS_ACCESS_KEY_ID}, \env{AWS_SECRET_ACCESS_KEY}, \env{AWS_SESSION_TOKEN}, \env{AWS_DEFAULT_REGION})
#'   \item an IAM instance role (on the running EC2 instance from which this function is called) as identified by \code{\link[aws.ec2metadata]{metadata}}
#'   \item a specified profile in a local credentials dot file in the current working directory
#'   \item the default profile in a local credentials dot file in the current working directory
#'   \item a specified profile in a global credentials dot file in, typically in \file{~/.aws/credentials}. See \code{\link{use_credentials}} for details
#'   \item the default profile in a global credentials dot file in, typically in \file{~/.aws/credentials}. See \code{\link{use_credentials}} for details
#' }
#' 
#' @seealso \code{\link{signature_v4}}, \code{\link{signature_v2_auth}}, \code{\link{use_credentials}}
#' @export
locate_credentials <- 
function(key = NULL, 
         secret = NULL, 
         session_token = NULL, 
         region = NULL, 
         file = NULL, 
         profile = "default", 
         default_region = "us-east-1",
         verbose = FALSE) {
    
    # grab environment variables
    env <- list(key = Sys.getenv("AWS_ACCESS_KEY_ID"),
                secret = Sys.getenv("AWS_SECRET_ACCESS_KEY"),
                session_token = Sys.getenv("AWS_SESSION_TOKEN"),
                region = Sys.getenv("AWS_DEFAULT_REGION"))
    
    # check for user-supplied values
    if (!is.null(key) || !is.null(secret)) {
        if (isTRUE(verbose)) {
            message("Using user-supplied value for AWS Access Key ID")
        }
        if (isTRUE(verbose)) {
            message("Using user-supplied value for AWS Secret Access Key")
        }
        if (!is.null(session_token)) {
            if (isTRUE(verbose)) {
                message("Using user-supplied value for AWS Session Token")
            }
        }
        if (!is.null(region)) {
            if (isTRUE(verbose)) {
                message(sprintf("Using user-supplied value for AWS Region ('%s')", region))
            }
        } else {
            region <- default_region
            if (isTRUE(verbose)) {
                message(sprintf("Using default value for AWS Region ('%s')", region))
            }
        }
    } else if (!is.null(key) || !is.null(secret)) {
        if (isTRUE(verbose)) {
            message("Using Environment Variable 'AWS_ACCESS_KEY_ID' for AWS Access Key ID")
            message("Using Environment Variable 'AWS_SECRET_ACCESS_KEY' for AWS Secret Access Key")
            message("Using Environment Variable 'AWS_SESSION_TOKEN' for AWS Session Token")
        }
        if (is.null(env$region) || env$region == "") {
            env$region <- default_region
            if (isTRUE(verbose)) {
                message(sprintf("Using default value for AWS Region ('%s')", region))
            }
        } else {
            message("Using Environment Variable 'AWS_DEFAULT_REGION' for AWS Region")
        }
        return(key)
    } else {
        # check for EC2 metadata
        role <- get_ec2_role(verbose = verbose)
        if (!is.null(role)) {
            if (!is.null(role[["AWS_ACCESS_KEY_ID"]])) {
                key <- role[["AWS_ACCESS_KEY_ID"]]
                if (isTRUE(verbose)) {
                    message("Using EC2 Instance Metadata for AWS Access Key ID")
                }
            }
            if (!is.null(role[["AWS_SECRET_ACCESS_KEY"]])) {
                secret <- role[["AWS_SECRET_ACCESS_KEY"]]
                if (isTRUE(verbose)) {
                    message("Using EC2 Instance Metadata for AWS Secret Access Key")
                }
            }
            if (!is.null(role[["AWS_SESSION_TOKEN"]])) {
                session_token <- role[["AWS_SESSION_TOKEN"]]
                if (isTRUE(verbose)) {
                    message("Using EC2 Instance Metadata for AWS Session Token")
                }
            }
            if (!is.null(role[["AWS_DEFAULT_REGION"]])) {
                region <- role[["AWS_DEFAULT_REGION"]]
                if (isTRUE(verbose)) {
                    message(sprintf("Using EC2 Instance Metadata for AWS Region ('%s')", region))
                }
            } else {
                region <- default_region
                if (isTRUE(verbose)) {
                    message(sprintf("Using default value for AWS Region ('%s')", region))
                }
            }
        } else {
            # check for credentials file
            if (file.exists(file.path(".aws", "credentials"))) {
                ## in working directory
                cred <- read_credentials(file.path(".aws", "credentials"))[[profile]]
                if (isTRUE(verbose)) {
                    message(sprintf("Using local credentials files from '%s'", file.path(".aws", "credentials")))
                }
            } else if (file.exists(default_credentials_file())) {
                ## in central location
                cred <- read_credentials()[[profile]]
                if (isTRUE(verbose)) {
                    message(sprintf("Using global credentials files from '%s'", default_credentials_file()))
                }
            } else {
                if (isTRUE(verbose)) {
                    warning("No instance metadata, environment variables, or credentials file found!")
                }
            }
            if (!is.null(cred[["AWS_ACCESS_KEY_ID"]])) {
                key <- cred[["AWS_ACCESS_KEY_ID"]]
                if (isTRUE(verbose)) {
                    message("Using EC2 Instance Metadata for AWS Access Key ID")
                }
            }
            if (!is.null(cred[["AWS_SECRET_ACCESS_KEY"]])) {
                secret <- cred[["AWS_SECRET_ACCESS_KEY"]]
                if (isTRUE(verbose)) {
                    message("Using EC2 Instance Metadata for AWS Secret Access Key")
                }
            }
            if (!is.null(cred[["AWS_SESSION_TOKEN"]])) {
                session_token <- cred[["AWS_SESSION_TOKEN"]]
                if (isTRUE(verbose)) {
                    message("Using EC2 Instance Metadata for AWS Session Token")
                }
            }
            if (!is.null(cred[["AWS_DEFAULT_REGION"]])) {
                region <- cred[["AWS_DEFAULT_REGION"]]
                if (isTRUE(verbose)) {
                    message(sprintf("Using EC2 Instance Metadata for AWS Region ('%s')", region))
                }
            } else {
                region <- default_region
                if (isTRUE(verbose)) {
                    message(sprintf("Using default value for AWS Region ('%s')", region))
                }
            }
        }
    }
    list(key = key, secret = secret, session_token = session_token, region = region)
}

get_ec2_role <- function(role, verbose = getOption("verbose", FALSE)) {
    if (!requireNamespace("aws.ec2metadata")) {
        return(NULL)
    }
    if (missing(role)) {
        role <- try(aws.ec2metadata::metadata$iam_role_names(), silent = TRUE)
        if (!length(role)) {
            stop("No IAM role profile available in instance metadata")
        }
        if (isTRUE(verbose)) {
            message("Using EC2 Instance Metadata")
        }
    }
    # return role credentials as list
    out <- try(aws.ec2metadata::metadata$iam_role(role[1L]), silent = TRUE)
    if (inherits(out, "try-errror")) {
        out <- NULL
    }
    out
}