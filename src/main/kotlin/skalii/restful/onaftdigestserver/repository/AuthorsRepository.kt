package skalii.restful.onaftdigestserver.repository


import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.data.repository.Repository as EmptyRepository
import org.springframework.stereotype.Repository

import skalii.restful.onaftdigestserver.entity.Author


@Repository
interface AuthorsRepository : EmptyRepository<Author, Int> {

    @Query(value = """select (author_search(
                          cast_int(:id_author),
                          cast_text(:full_name)
                      )).*""",
            nativeQuery = true)
    fun findSome(
            @Param("id_author") idAuthor: Int? = null,
            @Param("full_name") fullName: String? = null
    ): MutableList<Author>

    @Query(value = """select (author_search(all_record => true)).*""",
            nativeQuery = true)
    fun findAll(): MutableList<Author>

    @Query(value = """select (author_insert(
                          cast_text(:#{#author.fullName})
                      )).*""",
            nativeQuery = true)
    fun add(@Param("author") newAuthor: Author): Author

    @Query(value = """select (author_update(
                          cast_text(:#{#author.fullName}),
                          cast_int(:#{#author.idAuthor})
                      )).*""",
            nativeQuery = true)
    fun set(@Param("author") newAuthor: Author): Author

    @Query(value = """select (author_delete(cast_int(:id_author))).*""",
            nativeQuery = true)
    fun remove(@Param("id_author") idAuthor: Int): Author

}