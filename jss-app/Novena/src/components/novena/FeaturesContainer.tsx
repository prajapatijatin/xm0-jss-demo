import { Placeholder } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';

const FeaturesContainer = ({ rendering }: ComponentProps): JSX.Element => {
  return (
    <section className="features">
      <div className="container">
        <div className="row">
          <div className="col-lg-12">
            <div className="feature-block d-lg-flex">
              <Placeholder name="novena-jss-features" rendering={rendering} />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default FeaturesContainer;
