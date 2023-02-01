import { ComponentProps } from 'lib/component-props';
import queryString from 'query-string';
import { FormEvent } from 'react';
import config from 'temp/config';

const Login = ({ rendering }: ComponentProps): JSX.Element => {
  console.log(rendering);
  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    const data = {
      domain: 'extranet',
      username: event.target.username.value,
      password: event.target.password.value,
    };
    console.log(event);
    console.log(config);
    // const loginEndpoint = `${config.sitecoreApiHost}/sitecore/api/ssc/auth/login?sc_apikey=${config.sitecoreApiKey}`;
    const loginEndpoint = `/api/auth/login`;
    console.log(loginEndpoint);
    fetch(loginEndpoint, {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      credentials: 'include',
      method: 'POST',
      body: queryString.stringify(data),
    })
      .then((response) => {
        console.log(response);
      })
      .catch((err) => {
        console.log('error');
        console.log(err);
      });
  };
  return (
    <>
      <section className="contact-form-wrap section">
        <div className="container">
          <div className="row justify-content-center">
            <div className="col-lg-6">
              <div className="section-title text-center">
                <h2 className="text-md mb-2">Contact us</h2>
                <div className="divider mx-auto my-4"></div>
                <p className="mb-5">
                  Laboriosam exercitationem molestias beatae eos pariatur, similique, excepturi
                  mollitia sit perferendis maiores ratione aliquam?
                </p>
              </div>
            </div>
          </div>
          <div className="row">
            <div className="col-lg-12 col-md-12 col-sm-12">
              <form onSubmit={handleSubmit}>
                {/* <div className="row">
                        <div className="col-12">
                            <div className="alert alert-success contact__msg" style="display: none" role="alert">
                                Your message was sent successfully.
                            </div>
                        </div>
                    </div> */}

                <div className="row">
                  <div className="col-lg-6">
                    <div className="form-group">
                      <input
                        name="username"
                        id="username"
                        type="text"
                        className="form-control"
                        placeholder="User name"
                      ></input>
                    </div>
                  </div>

                  <div className="col-lg-6">
                    <div className="form-group">
                      <input
                        name="password"
                        id="password"
                        type="password"
                        className="form-control"
                        placeholder="Password"
                      ></input>
                    </div>
                  </div>
                </div>

                <div className="text-center">
                  <input
                    className="btn btn-main btn-round-full"
                    name="submit"
                    type="submit"
                    value="Send Messege"
                  ></input>
                </div>
              </form>
            </div>
          </div>
        </div>
      </section>
    </>
  );
};
export default Login;
