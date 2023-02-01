import React, { useEffect } from 'react';
import Head from 'next/head';
import {
  Placeholder,
  getPublicUrl,
  LayoutServiceData,
  Field,
} from '@sitecore-jss/sitecore-jss-nextjs';
import Scripts from 'src/Scripts';
import Header from 'components/novena/Header';

// Prefix public assets with a public URL to enable compatibility with Sitecore editors.
// If you're not supporting Sitecore editors, you can remove this.
const publicUrl = getPublicUrl();

interface LayoutProps {
  layoutData: LayoutServiceData;
}

interface RouteFields {
  [key: string]: unknown;
  Title: Field;
}

const NovenaLayout = ({ layoutData }: LayoutProps): JSX.Element => {
  useEffect(() => {
    require('assets/plugins/jquery/jquery.js');
    require('assets/plugins/bootstrap/js/bootstrap.min.js');
  }, []);

  const { route } = layoutData.sitecore;

  console.log(route);

  const fields = route?.fields as RouteFields;

  return (
    <>
      <Scripts />
      <Head>
        <title>{(fields && fields.Title && fields.Title.value.toString()) || 'Page'}</title>
        <link rel="icon" href={`${publicUrl}/favicon.ico`} />
      </Head>

      {/* root placeholder for the app, which we add components to using route data */}
      <header>{route && <Placeholder name="novena-headless-header" rendering={route} />}</header>
      {route && <Placeholder name="novena-headless-main" rendering={route} />}
      <footer className="footer section gray-bg">
        <div className="container">
          <div className="row">
            {route && <Placeholder name="novena-headless-footer-top" rendering={route} />}
          </div>
          <div className="footer-btm py-4 mt-5">
            {route && <Placeholder name="novena-headless-footer-bottom" rendering={route} />}
          </div>
        </div>
      </footer>
    </>
  );
};

export default NovenaLayout;
