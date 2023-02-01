import { NextApiRequest, NextApiResponse } from 'next';
import config from 'temp/config';
import queryString from 'query-string';
import { AxiosDataFetcher, AxiosDataFetcherConfig } from '@sitecore-jss/sitecore-jss-nextjs';

export default async function handler(req: NextApiRequest, res: NextApiResponse): Promise<void> {
  console.log('Login handler');
  console.log(req.body);
  const { response, error } = await login(req.body.username, req.body.password);
  if (response) {
    const cookies = response.headers['set-cookie'];
    res.setHeader('set-cookie', cookies);
    res.status(200).json({ data: true });
  } else {
    console.log(error.response);
    res.status(401).json({ data: false });
  }
}

const login = async (userName: string, password: string) => {
  const data = {
    domain: 'extranet',
    username: userName,
    password: password,
  };
  console.log(data);
  const axiosConfig: AxiosDataFetcherConfig = {
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    withCredentials: true,
    method: 'POST',
  };
  const axiosDataFetcher = new AxiosDataFetcher(axiosConfig);
  const loginEndpoint = `${config.sitecoreApiHost}/sitecore/api/ssc/auth/login?sc_apikey=${config.sitecoreApiKey}`;
  console.log(loginEndpoint);
  try {
    const response = await axiosDataFetcher.post(loginEndpoint, queryString.stringify(data));
    return { response };
  } catch (error) {
    return { error };
  }
};
