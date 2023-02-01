import React from 'react';
import {
  Image as JssImage,
  Link as JssLink,
  ImageField,
  Field,
  LinkField,
  Text,
  RichText,
  NextImage,
} from '@sitecore-jss/sitecore-jss-nextjs';

interface Fields {
  PromoIcon: ImageField;
  PromoText: Field<string>;
  PromoLink: LinkField;
  PromoText2: Field<string>;
}

type PromoProps = {
  params: { [key: string]: string };
  fields: Fields;
};

const PromoDefaultComponent = (props: PromoProps): JSX.Element => (
  <div className={`component promo ${props.params.styles}`}>
    <div className="component-content">
      <span className="is-empty-hint">Promo</span>
    </div>
  </div>
);

export const Default = (props: PromoProps): JSX.Element => {
  if (props.fields) {
    return (
      <div className={`component promo ${props.params.styles}`}>
        <div className="component-content card">
          <div className="card-img-top">
            <JssImage field={props.fields.PromoIcon} />
          </div>
          <div className="card-body">
            <div className="card-text">
              <Text className="image-caption" field={props.fields.PromoText} />
            </div>
            <div className="card-text">
              <JssLink field={props.fields.PromoLink} className="btn btn-light" />
            </div>
          </div>
        </div>
      </div>
    );
  }

  return <PromoDefaultComponent {...props} />;
};

export const WithText = (props: PromoProps): JSX.Element => {
  if (props.fields) {
    return (
      <div className={`component promo ${props.params.styles}`}>
        <div className="component-content">
          <div className="field-promoicon">
            <JssImage field={props.fields.PromoIcon} />
          </div>
          <div className="promo-text">
            <div>
              <div className="field-promotext">
                <Text className="promo-text" field={props.fields.PromoText} />
              </div>
            </div>
            <div className="field-promotext">
              <Text className="promo-text" field={props.fields.PromoText2} />
            </div>
          </div>
        </div>
      </div>
    );
  }

  return <PromoDefaultComponent {...props} />;
};

export const WithHeadingTextAndImage = (props: PromoProps): JSX.Element => {
  if (props.fields) {
    return (
      <section className="section about-page">
        <div className="container">
          <div className="row">
            <div className="col-lg-4">
              <Text field={props.fields.PromoText2} className="title-color" tag="h2"></Text>
            </div>
            <div className="col-lg-8">
              <RichText field={props.fields.PromoText} tag="p"></RichText>
              <NextImage field={props.fields.PromoIcon} alt="" className="img-fluid"></NextImage>
            </div>
          </div>
        </div>
      </section>
    );
  }

  return <PromoDefaultComponent {...props} />;
};
