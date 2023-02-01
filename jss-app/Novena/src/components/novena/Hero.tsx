import {
  ImageField,
  Link,
  LinkField,
  Text,
  TextField,
  withDatasourceCheck,
} from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';

type HeroFields = {
  Heading: TextField;
  TagLine: TextField;
  CTA: LinkField;
  BackgroundImage: ImageField;
  Description: TextField;
};

type HeroProps = ComponentProps & {
  fields: HeroFields;
};
const Hero = (props: HeroProps): JSX.Element => {
  return (
    <>
      <section
        className="banner"
        style={{ backgroundImage: `url(${props.fields.BackgroundImage.value.src})` }}
      >
        <div className="container">
          <div className="row">
            <div className="col-lg-6 col-md-12 col-xl-7">
              <div className="block">
                <div className="divider mb-3"></div>
                <Text
                  field={props.fields.TagLine}
                  tag="span"
                  className="text-uppercase text-sm letter-spacing"
                />
                <Text field={props.fields.Heading} tag="h1" className="mb-3 mt-3" />
                <Text field={props.fields.Description} tag="p" className="mb-3 mt-3" />
                <div className="btn-container">
                  <Link
                    field={props.fields.CTA}
                    className="btn btn-main-2 btn-icon btn-round-full"
                  ></Link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
};

export default withDatasourceCheck()<HeroProps>(Hero);
