import {
  NextImage,
  ImageField,
  Text,
  TextField,
  useSitecoreContext,
} from '@sitecore-jss/sitecore-jss-nextjs';
import Link from 'next/link';

interface RouteFields {
  [key: string]: unknown;
  Title: TextField;
  BackgroundImage: ImageField;
}

const PageTitleWithBackground = (): JSX.Element => {
  const { route, pageEditing } = useSitecoreContext().sitecoreContext;

  const fields = route?.fields as RouteFields;
  return (
    <>
      <section
        className="page-title bg-1"
        style={{ backgroundImage: `url(${fields?.BackgroundImage?.value.src})` }}
      >
        <div className="overlay"></div>
        <div className="container">
          <div className="row">
            <div className="col-md-12">
              <div className="block text-center">
                <span className="text-white">{fields.Title.value}</span>
                <Text field={fields.Title} tag="h1" className="text-capitalize mb-5 text-lg"></Text>
                {pageEditing && (
                  <NextImage field={fields?.BackgroundImage} height="60" width="212" />
                )}
              </div>
            </div>
          </div>
        </div>
      </section>
      {/* <Link href="/my-account">My account</Link> */}
    </>
  );
};

export default PageTitleWithBackground;
