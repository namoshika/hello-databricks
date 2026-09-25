import uuid

import pandas as pd
from pyspark.sql.functions import pandas_udf
from pyspark.sql.types import StringType

FRONT_MATTER_DELIMITER = "---\n"


@pandas_udf(returnType=StringType())
def uuid5(name: pd.Series) -> pd.Series:
    """文字列から UUID5 を生成する.

    Args:
        name: UUID5 生成元の文字列を持つ列 (例: F.col("name"))。

    Returns:
        UUID5 文字列を持つ列。
    """
    return name.map(lambda n: str(uuid.uuid5(uuid.NAMESPACE_URL, n)))
