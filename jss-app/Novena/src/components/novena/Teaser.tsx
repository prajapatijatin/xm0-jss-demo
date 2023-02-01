import {
  Link,
  LinkField,
  RichText,
  RichTextField,
  Text,
  TextField,
  withDatasourceCheck,
} from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';

type TeaserFields = {
  Heading: TextField;
  TagLine: TextField;
  CTA: LinkField;
  IconClass: TextField;
  Text: RichTextField;
};

type TeaserProps = ComponentProps & {
  fields: TeaserFields;
};

const Teaser = (props: TeaserProps): JSX.Element => {
  return (
    <>
      <div className="feature-item mb-5 mb-lg-0">
        <div className="feature-icon mb-4">
          {props.fields?.IconClass?.value && <i className={props.fields.IconClass.value || ''}></i>}
        </div>
        <Text field={props.fields.TagLine} tag="span" />
        <Text field={props.fields.Heading} tag="h4" className="mb-3" />
        <RichText field={props.fields.Text} className="mb-4" />
        {props.fields.CTA && props.fields.CTA.value && props.fields.CTA.value.href !== '' && (
          <Link
            field={props.fields.CTA}
            className="btn btn-main btn-round-full"
            showLinkTextWithChildrenPresent={true}
          >
            <i className="icofont-simple-right ml-3"></i>
          </Link>
        )}
      </div>
    </>
  );
};

export default withDatasourceCheck()<TeaserProps>(Teaser);
