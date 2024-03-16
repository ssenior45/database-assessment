# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
from __future__ import annotations

from typing import Any

import aiosql
from aiosql.queries import Queries
from rich.padding import Padding

from dma.cli._utils import console
from dma.lib.db.query_manager import QueryManager
from dma.utils import module_to_os_path

_root_path = module_to_os_path("dma")


class CollectionQueryManager(QueryManager):
    """Collection Query Manager"""

    async def execute_collection_queries(self, *args: Any, **kwargs: Any) -> dict[str, Any]:
        """Execute pre-processing queries."""
        console.print(Padding("COLLECTION QUERIES", 1, style="bold magenta on white", expand=True), width=80)
        with console.status("[bold green]Executing queries...[/]") as _status:
            results: dict[str, Any] = {}
            for script in self.available_queries("collection"):
                console.log(rf" [yellow]*[/] Executing [bold magenta]`{script}`[/]")
                script_result = await self.select(script, PKEY="test", DMA_SOURCE_ID="testing", DMA_MANUAL_ID=None)
                results[script] = script_result
            if not self.available_queries("collection"):
                console.log(" [dim grey]* No collection queries for this database type[/]")
            return results

    async def execute_extended_collection_queries(self) -> dict[str, Any]:
        """Execute extended collection queries.

        Returns: None
        """
        console.print(Padding("EXTENDED COLLECTION QUERIES", 1, style="bold magenta on white", expand=True), width=80)
        with console.status("[bold green]Executing queries...[/]") as _status:
            results: dict[str, Any] = {}
            for script in self.available_queries("extended_collection"):
                console.log(rf" [yellow]*[/] Executing [bold magenta]`{script}`[/]")
                script_result = await self.select(script, PKEY="test", DMA_SOURCE_ID="testing", DMA_MANUAL_ID=None)
                results[script] = script_result
            if not self.available_queries("extended_collection"):
                console.log(" [dim grey]* No extended collection queries for this database type[/]")
            return results


class PostgresCollectionQueryManager(CollectionQueryManager):
    def __init__(
        self,
        connection: Any,
        queries: Queries = aiosql.from_path(
            sql_path=f"{_root_path}/collector/sql/sources/postgres", driver_adapter="asyncpg"
        ),
    ) -> None:
        super().__init__(connection, queries)


class PostgresCollectionQueryManager(CollectionQueryManager):
    def __init__(
        self,
        connection: Any,
        queries: Queries = aiosql.from_path(
            sql_path=f"{_root_path}/collector/sql/sources/postgres", driver_adapter="asyncpg"
        ),
    ) -> None:
        super().__init__(connection, queries)


class PostgresCollectionQueryManager(CollectionQueryManager):
    def __init__(
        self,
        connection: Any,
        queries: Queries = aiosql.from_path(
            sql_path=f"{_root_path}/collector/sql/sources/postgres", driver_adapter="asyncpg"
        ),
    ) -> None:
        super().__init__(connection, queries)


class SQLServerCollectionQueryManager(CollectionQueryManager):
    def __init__(
        self,
        connection: Any,
        queries: Queries = aiosql.from_path(
            sql_path=f"{_root_path}/collector/sql/sources/mssql", driver_adapter="aioodbc"
        ),
    ) -> None:
        super().__init__(connection, queries)


class CanonicalQueryManager(QueryManager):
    """Canonical Query Manager"""

    def execute_transformation_queries(self, *args: Any, **kwargs: Any) -> dict[str, Any]:
        """Execute pre-processing queries."""
        console.print(Padding("TRANSFORMATION QUERIES", 1, style="bold magenta on white", expand=True), width=80)
        with console.status("[bold green]Executing queries...[/]") as _status:
            results: dict[str, Any] = {}
            for script in self.available_queries("transformation"):
                console.log(rf" [yellow]*[/] Executing [bold magenta]`{script}`[/]")
                script_result = self.select(script, PKEY="test", DMA_SOURCE_ID="testing", DMA_MANUAL_ID=None)
                results[script] = script_result
            if not self.available_queries("transformation"):
                console.log(" [dim grey]* No transformation queries for this database type[/]")
            return results

    def execute_assessment_queries(
        self,
        pkey: str = "test",
        dma_source_id: str = "testing",
        dma_manual_id: str | None = None,
        *args: Any,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Execute pre-processing queries."""
        console.print(Padding("ASSESSMENT QUERIES", 1, style="bold magenta on white", expand=True), width=80)
        with console.status("[bold green]Executing queries...[/]") as _status:
            results: dict[str, Any] = {}
            for script in self.available_queries("assessment"):
                console.print(rf" [yellow]*[/] Executing [bold magenta]`{script}`[/]")
                script_result = self.select(script, PKEY="test", DMA_SOURCE_ID="testing", DMA_MANUAL_ID=None)
                results[script] = script_result
            if not self.available_queries("assessment"):
                console.log(" [dim grey]* No assessment queries for this database type[/]")
            return results
