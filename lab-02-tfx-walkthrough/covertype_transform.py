
import tensorflow as tf
import tensorflow_transform as tft

NUMERIC_FEATURES_KEYS = ['Elevation', 'Aspect', 'Slope', 'Horizontal_Distance_To_Hydrology',
    'Vertical_Distance_To_Hydrology', 'Horizontal_Distance_To_Roadways',
    'Hillshade_9am', 'Hillshade_Noon', 'Hillshade_3pm',
    'Horizontal_Distance_To_Fire_Points']

CATEGORICAL_FEATURES_KEYS = ['Wilderness_Area', 'Soil_Type']

LABEL_KEY = 'Cover_Type'


def _transformed_name(key):
    return key + '_xf'

def _fill_in_missing(x):
    """Replace missing values in a SparseTensor.

    Fills in missing values of `x` with '' or 0, and converts to a dense tensor.

    Args:
      x: A `SparseTensor` of rank 2.  Its dense shape should have size at most 1
        in the second dimension.

    Returns:
      A rank 1 tensor where missing values of `x` have been filled in.
    """
    default_value = '' if x.dtype == tf.string else 0
    return tf.squeeze(
        tf.sparse.to_dense(
            tf.SparseTensor(x.indices, x.values, [x.dense_shape[0], 1]),
            default_value),
        axis=1)

def preprocessing_fn(inputs):
    """Preprocesses Covertype Dataset.
    
    Scales numerical features and generates vocabularies
    and mappings for categorical features.
    
    Args:
        inputs: A map from feature keys to raw not-yet-transformed features
        
    Returns:
        A map from transformed feature keys to transformation operations
    """
    
    outputs = {}
    
    # Scale numerical features
    for key in NUMERIC_FEATURES_KEYS:
        outputs[_transformed_name(key)] = tft.scale_to_z_score(_fill_in_missing(inputs[key]))
        
    # Generate vocabularies and maps categorical features
    for key in CATEGORICAL_FEATURES_KEYS:
        outputs[_transformed_name(key)] = tft.compute_and_apply_vocabulary(
        x=_fill_in_missing(inputs[key]),
        num_oov_buckets=1,
        vocab_filename=key)
        
        
    # Convert Cover_Type from 1-7 to 0-6 
    outputs[_transformed_name(LABEL_KEY)] = _fill_in_missing(inputs[LABEL_KEY]) - 1
    
    return outputs
    